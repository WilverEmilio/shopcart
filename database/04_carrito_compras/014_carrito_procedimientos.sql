/* =============================================================================
   014_Carrito_Procedimientos.sql
   Módulo 4 - Carrito: obtener, agregar, actualizar cantidad, eliminar y fusionar.
   Reejecutable (CREATE OR ALTER).

   Identificación del carrito: SIEMPRE por @IDUsuario (sale del JWT) o por
   @TokenHash (SHA-256 del token del invitado, calculado por el backend); nunca
   por un IDCarrito enviado por el cliente. Debe indicarse exactamente uno.

   Códigos de error personalizados (THROW):
     50080 Debe indicar el usuario o el token (solo uno)          -> 400
     50081 Carrito no encontrado                                  -> 404
     50082 La cantidad excede la existencia disponible            -> 409
     50083 El producto no está en el carrito                      -> 404
     50084 Carrito modificado en paralelo; reintentar             -> 409
   Reutiliza: 50053 (token inválido), 50057 (variante no existe),
              50066 (cantidad inválida), 50068 (no disponible para la venta).

   Nota para el checkout (módulo 6): bloquear primero la fila del carrito y
   después reservar, igual que aquí, para mantener el orden de bloqueos y evitar
   interbloqueos.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Carrito_ResolverCarrito
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @Crear      BIT      = 0,
    @Bloquear   BIT      = 1,
    @IDCarrito  INT      = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@IDUsuario IS NULL AND @TokenHash IS NULL) OR (@IDUsuario IS NOT NULL AND @TokenHash IS NOT NULL)
        THROW 50080, N'Debe indicar el usuario o el token del carrito de invitado (solo uno).', 1;

    IF @TokenHash IS NOT NULL AND (LEN(@TokenHash) <> 64 OR @TokenHash LIKE N'%[^0-9a-fA-F]%')
        THROW 50053, N'El token del carrito no es válido.', 1;

    IF @IDUsuario IS NOT NULL
        EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @IDCarrito = NULL;

    IF @Bloquear = 1
    BEGIN
        IF @IDUsuario IS NOT NULL
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
            WHERE IDUsuario = @IDUsuario AND Estado = N'ACTIVO';
        ELSE
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
            WHERE TokenHash = @TokenHash AND Estado = N'ACTIVO';
    END
    ELSE
    BEGIN
        IF @IDUsuario IS NOT NULL
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos
            WHERE IDUsuario = @IDUsuario AND Estado = N'ACTIVO';
        ELSE
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos
            WHERE TokenHash = @TokenHash AND Estado = N'ACTIVO';
    END;

    IF @IDCarrito IS NULL AND @Crear = 1
    BEGIN
        INSERT INTO dbo.Carritos (IDUsuario, TokenHash) VALUES (@IDUsuario, @TokenHash);
        SET @IDCarrito = SCOPE_IDENTITY();
    END;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Carrito_LiberarReservaUsuario
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDReserva INT;

    SELECT @IDReserva = IDReserva
    FROM   dbo.Reservas WITH (UPDLOCK, HOLDLOCK)
    WHERE  IDUsuario = @IDUsuario AND Estado = N'ACTIVA';

    IF @IDReserva IS NOT NULL
        EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDReserva, @NuevoEstado = N'LIBERADA';
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_Obtener
    @IDUsuario INT      = NULL,
    @TokenHash CHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDCarrito INT;

    EXEC Interno.SP_Carrito_ResolverCarrito
        @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 0, @IDCarrito = @IDCarrito OUTPUT;

    SELECT  @IDCarrito AS IDCarrito, t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva, t.Lineas
    FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;

    SELECT  d.IDVariante,
            v.SKU,
            p.IDProducto,
            p.Nombre AS Producto,
            (SELECT STRING_AGG(CONCAT(a.Nombre, N': ', va.Valor), N', ') WITHIN GROUP (ORDER BY a.Nombre)
             FROM dbo.VarianteAtributos va
             JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
             WHERE va.IDVariante = v.IDVariante) AS Atributos,
            v.Precio,
            d.Cantidad,
            CAST(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio AS DECIMAL(18,2)) AS Subtotal,
            v.ExistenciaDisponible AS Disponible,
            CAST(CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END AS BIT) AS Vendible,
            CAST(CASE WHEN d.Cantidad > v.ExistenciaDisponible THEN 1 ELSE 0 END AS BIT)            AS ExcedeExistencia,
            i.Url AS ImagenPrincipal
    FROM    dbo.CarritosDetalle d
    JOIN    dbo.Variantes v  ON v.IDVariante = d.IDVariante
    JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
    JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
    LEFT JOIN dbo.ImagenesProducto i ON i.IDProducto = p.IDProducto AND i.EsPrincipal = 1
    WHERE   d.IDCarrito = @IDCarrito
    ORDER BY d.FechaCreacion, d.IDVariante;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_AgregarProducto
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @IDVariante INT,
    @Cantidad   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 50066, N'La cantidad debe ser mayor a cero.', 1;

    DECLARE @IDCarrito INT, @SKU NVARCHAR(50), @Disponible INT, @Vendible BIT,
            @Actual INT = 0, @Nueva INT, @Mensaje NVARCHAR(400);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 1, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        SELECT  @SKU = v.SKU,
                @Disponible = v.ExistenciaDisponible,
                @Vendible = CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END
        FROM    dbo.Variantes v
        JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
        JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE   v.IDVariante = @IDVariante;

        IF @SKU IS NULL
            THROW 50057, N'El producto solicitado no existe.', 1;
        IF @Vendible = 0
            THROW 50068, N'El producto no está disponible para la venta.', 1;

        SELECT @Actual = Cantidad
        FROM   dbo.CarritosDetalle
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        SET @Nueva = @Actual + @Cantidad;

        IF @Nueva > @Disponible
        BEGIN
            SET @Mensaje = CONCAT(N'No hay existencia suficiente del SKU ', @SKU, N': tiene ', @Actual,
                                  N' en el carrito, solicita ', @Cantidad, N' más y hay ', @Disponible, N' disponible(s).');
            THROW 50082, @Mensaje, 1;
        END;

        UPDATE dbo.CarritosDetalle
        SET    Cantidad = @Nueva
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        IF @@ROWCOUNT = 0
            INSERT INTO dbo.CarritosDetalle (IDCarrito, IDVariante, Cantidad)
            VALUES (@IDCarrito, @IDVariante, @Nueva);

        UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarrito;

        IF @IDUsuario IS NOT NULL
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDCarrito AS IDCarrito, @IDVariante AS IDVariante, @Nueva AS Cantidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
           AND (ERROR_MESSAGE() LIKE N'%UX_Carritos_UsuarioActivo%' OR ERROR_MESSAGE() LIKE N'%UX_Carritos_TokenHash%')
            THROW 50084, N'El carrito se está modificando en otra solicitud; intente de nuevo.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_ActualizarCantidad
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @IDVariante INT,
    @Cantidad   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 50066, N'La cantidad debe ser mayor a cero.', 1;

    DECLARE @IDCarrito INT, @SKU NVARCHAR(50), @Disponible INT, @Vendible BIT,
            @Existe INT, @Mensaje NVARCHAR(400);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        SELECT @Existe = IDVariante
        FROM   dbo.CarritosDetalle
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        IF @Existe IS NULL
            THROW 50083, N'El producto no está en el carrito.', 1;

        SELECT  @SKU = v.SKU,
                @Disponible = v.ExistenciaDisponible,
                @Vendible = CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END
        FROM    dbo.Variantes v
        JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
        JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE   v.IDVariante = @IDVariante;

        IF @Vendible = 0
            THROW 50068, N'El producto no está disponible para la venta.', 1;

        IF @Cantidad > @Disponible
        BEGIN
            SET @Mensaje = CONCAT(N'No hay existencia suficiente del SKU ', @SKU, N': solicita ', @Cantidad,
                                  N' y hay ', @Disponible, N' disponible(s).');
            THROW 50082, @Mensaje, 1;
        END;

        UPDATE dbo.CarritosDetalle
        SET    Cantidad = @Cantidad
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarrito;

        IF @IDUsuario IS NOT NULL
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDCarrito AS IDCarrito, @IDVariante AS IDVariante, @Cantidad AS Cantidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_EliminarProducto
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @IDVariante INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IDCarrito INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        DELETE FROM dbo.CarritosDetalle
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        IF @@ROWCOUNT = 0
            THROW 50083, N'El producto no está en el carrito.', 1;

        UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarrito;

        IF @IDUsuario IS NOT NULL
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDCarrito AS IDCarrito, @IDVariante AS IDVariante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_Fusionar
    @IDUsuario INT,
    @TokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @IDUsuario IS NULL OR @TokenHash IS NULL
        THROW 50080, N'Debe indicar el usuario y el token del carrito de invitado.', 1;
    IF LEN(@TokenHash) <> 64 OR @TokenHash LIKE N'%[^0-9a-fA-F]%'
        THROW 50053, N'El token del carrito no es válido.', 1;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    DECLARE @IDInvitado INT, @IDCarritoUsuario INT, @Fusionado BIT = 0;
    DECLARE @Plan TABLE (
        IDVariante   INT PRIMARY KEY,
        SKU          NVARCHAR(50) NOT NULL,
        CantInvitado INT NOT NULL,
        CantUsuario  INT NOT NULL,
        Objetivo     INT NOT NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IDCarritoUsuario = IDCarrito
        FROM   dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDUsuario = @IDUsuario AND Estado = N'ACTIVO';

        SELECT @IDInvitado = IDCarrito
        FROM   dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
        WHERE  TokenHash = @TokenHash AND Estado = N'ACTIVO';

        IF @IDInvitado IS NOT NULL
        BEGIN
            IF @IDCarritoUsuario IS NULL
            BEGIN
                UPDATE dbo.Carritos
                SET    IDUsuario = @IDUsuario, TokenHash = NULL, FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDCarrito = @IDInvitado;

                SET @IDCarritoUsuario = @IDInvitado;
            END
            ELSE
            BEGIN
                INSERT INTO @Plan (IDVariante, SKU, CantInvitado, CantUsuario, Objetivo)
                SELECT  g.IDVariante, v.SKU, g.Cantidad, ISNULL(u.Cantidad, 0),
                        CASE
                            WHEN NOT (v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1)
                                THEN ISNULL(u.Cantidad, 0)
                            WHEN ISNULL(u.Cantidad, 0) + g.Cantidad <= v.ExistenciaDisponible
                                THEN ISNULL(u.Cantidad, 0) + g.Cantidad
                            WHEN v.ExistenciaDisponible > ISNULL(u.Cantidad, 0)
                                THEN v.ExistenciaDisponible
                            ELSE ISNULL(u.Cantidad, 0)
                        END
                FROM    dbo.CarritosDetalle g
                JOIN    dbo.Variantes v  ON v.IDVariante = g.IDVariante
                JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
                JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
                LEFT JOIN dbo.CarritosDetalle u
                        ON u.IDCarrito = @IDCarritoUsuario AND u.IDVariante = g.IDVariante
                WHERE   g.IDCarrito = @IDInvitado;

                UPDATE u
                SET    u.Cantidad = p.Objetivo
                FROM   dbo.CarritosDetalle u
                JOIN   @Plan p ON p.IDVariante = u.IDVariante
                WHERE  u.IDCarrito = @IDCarritoUsuario
                  AND  p.Objetivo <> u.Cantidad;

                INSERT INTO dbo.CarritosDetalle (IDCarrito, IDVariante, Cantidad)
                SELECT @IDCarritoUsuario, IDVariante, Objetivo
                FROM   @Plan
                WHERE  CantUsuario = 0 AND Objetivo > 0;

                UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarritoUsuario;

                UPDATE dbo.Carritos
                SET    Estado = N'FUSIONADO', IDUsuario = @IDUsuario, TokenHash = NULL,
                       FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDCarrito = @IDInvitado;
            END;

            SET @Fusionado = 1;
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;
        END;

        COMMIT TRANSACTION;

        SELECT @IDCarritoUsuario AS IDCarrito, @Fusionado AS Fusionado;

        SELECT IDVariante, SKU, CantInvitado AS Solicitada, Objetivo - CantUsuario AS Aplicada
        FROM   @Plan
        WHERE  Objetivo - CantUsuario < CantInvitado
        ORDER BY IDVariante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'014_Carrito_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'014_Carrito_Procedimientos.sql');
GO