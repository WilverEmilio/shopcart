/* =============================================================================
   016_Cupones_Procedimientos.sql
   Módulo 5 - Cupones: validación y cálculo del descuento, CRUD administrativo,
   aplicación al carrito y registro/reversión de usos. Reejecutable.

   Este script también REDEFINE FU_Carrito_Totales y SP_Carrito_Obtener (creados
   en los scripts 013 y 014) para incluir el descuento del cupón: el carrito y
   el checkout usan siempre el mismo cálculo.

   Códigos de error personalizados (THROW):
     50090 Código de cupón duplicado                              -> 409
     50091 Cupón no encontrado                                    -> 404
     50093 El límite total no puede ser menor a los usos actuales -> 409
     50094 El cupón ya fue usado: no se puede eliminar            -> 409
     50095 Cupón no aplicable. El STATE del error indica el motivo y el
           mensaje es específico para mostrarlo al cliente        -> 409
              STATE 1 INACTIVO              2 NO_VIGENTE
                    3 VENCIDO               4 AGOTADO
                    5 LIMITE_CLIENTE        6 CARRITO_VACIO
                    7 SIN_PRODUCTOS_CATEGORIA  8 MINIMO_NO_ALCANZADO
   Reutiliza: 50040 (categoría no existe), 50053 (datos inválidos),
              50081 (carrito no existe).

   Reglas de negocio:
     - Descuento PORCENTAJE = ROUND(subtotal elegible x % / 100, 2).
       Descuento MONTO_FIJO = valor. En ambos casos se limita al subtotal
       elegible, así el total del pedido nunca baja de cero.
     - Subtotal elegible = todo el carrito, o solo las líneas de la categoría
       del cupón. El monto mínimo se compara contra el subtotal del carrito.
     - El descuento se aplica sobre precios que ya incluyen IVA; el desglose
       de IVA se calcula sobre el total ya descontado.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER FUNCTION dbo.FU_Cupones_MensajeRechazo (@Codigo NVARCHAR(30))
RETURNS TABLE
AS
RETURN (
    SELECT m.Mensaje, m.Estado
    FROM (VALUES
        (N'INACTIVO',                N'El cupón no está activo.',                                                   1),
        (N'NO_VIGENTE',              N'El cupón aún no está vigente.',                                              2),
        (N'VENCIDO',                 N'El cupón está vencido.',                                                     3),
        (N'AGOTADO',                 N'El cupón ya alcanzó su límite total de usos.',                               4),
        (N'LIMITE_CLIENTE',          N'Ya alcanzó el límite de usos de este cupón por cliente.',                    5),
        (N'CARRITO_VACIO',           N'El carrito está vacío; agregue productos para usar el cupón.',               6),
        (N'SIN_PRODUCTOS_CATEGORIA', N'El carrito no tiene productos de la categoría a la que aplica el cupón.',    7),
        (N'MINIMO_NO_ALCANZADO',     N'El subtotal del carrito no alcanza la compra mínima del cupón.',             8)
    ) AS m (Codigo, Mensaje, Estado)
    WHERE m.Codigo = @Codigo
);
GO

CREATE OR ALTER FUNCTION dbo.FU_Cupones_CalculoDescuento (@IDCupon INT, @IDCarrito INT, @IDUsuario INT)
RETURNS TABLE
AS
RETURN (
    SELECT  z.IDCupon,
            z.SubtotalCarrito,
            z.SubtotalElegible,
            z.CodigoRechazo,
            CAST(CASE
                    WHEN z.CodigoRechazo IS NOT NULL THEN 0
                    WHEN z.TipoDescuento = N'PORCENTAJE' THEN ROUND(z.SubtotalElegible * z.Valor / 100, 2)
                    WHEN z.Valor > z.SubtotalElegible THEN z.SubtotalElegible
                    ELSE z.Valor
                 END AS DECIMAL(18,2)) AS Descuento
    FROM (
        SELECT  c.IDCupon, c.TipoDescuento, c.Valor, s.SubtotalCarrito, s.SubtotalElegible,
                CASE
                    WHEN c.Activo = 0 THEN N'INACTIVO'
                    WHEN SYSUTCDATETIME() < c.FechaInicio THEN N'NO_VIGENTE'
                    WHEN SYSUTCDATETIME() > c.FechaFin THEN N'VENCIDO'
                    WHEN c.LimiteUsosTotal IS NOT NULL AND c.UsosActuales >= c.LimiteUsosTotal THEN N'AGOTADO'
                    WHEN c.LimiteUsosPorCliente IS NOT NULL AND u.Usos >= c.LimiteUsosPorCliente THEN N'LIMITE_CLIENTE'
                    WHEN s.SubtotalCarrito <= 0 THEN N'CARRITO_VACIO'
                    WHEN c.IDCategoria IS NOT NULL AND s.SubtotalElegible <= 0 THEN N'SIN_PRODUCTOS_CATEGORIA'
                    WHEN s.SubtotalCarrito < c.MontoMinimo THEN N'MINIMO_NO_ALCANZADO'
                END AS CodigoRechazo
        FROM    dbo.Cupones c
        CROSS APPLY (
            SELECT  CAST(ISNULL(SUM(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio), 0) AS DECIMAL(18,2)) AS SubtotalCarrito,
                    CAST(ISNULL(SUM(CASE WHEN c.IDCategoria IS NULL OR p.IDCategoria = c.IDCategoria
                                         THEN CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio END), 0) AS DECIMAL(18,2)) AS SubtotalElegible
            FROM    dbo.CarritosDetalle d
            JOIN    dbo.Variantes v  ON v.IDVariante = d.IDVariante
            JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
            JOIN    dbo.Categorias ca ON ca.IDCategoria = p.IDCategoria
            WHERE   d.IDCarrito = @IDCarrito
                AND v.Activo = 1 AND p.Activo = 1 AND ca.Activo = 1
        ) s
        CROSS APPLY (
            SELECT COUNT(*) AS Usos
            FROM   dbo.UsosCupones uc
            WHERE  uc.IDCupon = c.IDCupon AND uc.IDUsuario = @IDUsuario AND uc.Estado = N'APLICADO'
        ) u
        WHERE   c.IDCupon = @IDCupon
    ) z
);
GO

CREATE OR ALTER FUNCTION dbo.FU_Carrito_Totales (@IDCarrito INT)
RETURNS TABLE
AS
RETURN (
    SELECT  x.Subtotal,
            x.Descuento,
            x.Total,
            CAST(ROUND(x.Total / 1.12, 2) AS DECIMAL(18,2))           AS BaseImponible,
            CAST(x.Total - ROUND(x.Total / 1.12, 2) AS DECIMAL(18,2)) AS Iva,
            x.Lineas,
            x.IDCupon,
            x.CuponRechazo
    FROM (
        SELECT  s.Subtotal,
                s.Lineas,
                CAST(ISNULL(d.Descuento, 0) AS DECIMAL(18,2))                 AS Descuento,
                CAST(s.Subtotal - ISNULL(d.Descuento, 0) AS DECIMAL(18,2))    AS Total,
                ca.IDCupon,
                d.CodigoRechazo                                               AS CuponRechazo
        FROM (
            SELECT  CAST(ISNULL(SUM(CAST(dt.Cantidad AS DECIMAL(18,2)) * v.Precio), 0) AS DECIMAL(18,2)) AS Subtotal,
                    COUNT(dt.IDVariante) AS Lineas
            FROM    dbo.CarritosDetalle dt
            JOIN    dbo.Variantes v   ON v.IDVariante = dt.IDVariante
            JOIN    dbo.Productos p   ON p.IDProducto = v.IDProducto
            JOIN    dbo.Categorias c  ON c.IDCategoria = p.IDCategoria
            WHERE   dt.IDCarrito = @IDCarrito
                AND v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1
        ) s
        LEFT JOIN dbo.Carritos ca ON ca.IDCarrito = @IDCarrito
        OUTER APPLY dbo.FU_Cupones_CalculoDescuento(ca.IDCupon, @IDCarrito, ca.IDUsuario) d
    ) x
);
GO

CREATE OR ALTER PROCEDURE Interno.SP_Cupones_ValidarDatos
    @TipoDescuento        NVARCHAR(12),
    @Valor                DECIMAL(12,2),
    @IDCategoria          INT,
    @MontoMinimo          DECIMAL(12,2),
    @FechaInicio          DATETIME2(0),
    @FechaFin             DATETIME2(0),
    @LimiteUsosTotal      INT,
    @LimiteUsosPorCliente INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @TipoDescuento IS NULL OR @TipoDescuento NOT IN (N'PORCENTAJE', N'MONTO_FIJO')
        THROW 50053, N'El tipo de descuento debe ser PORCENTAJE o MONTO_FIJO.', 1;
    IF @Valor IS NULL OR @Valor <= 0
        THROW 50053, N'El valor del descuento debe ser mayor a cero.', 1;
    IF @TipoDescuento = N'PORCENTAJE' AND @Valor > 100
        THROW 50053, N'El porcentaje de descuento no puede superar 100.', 1;
    IF @MontoMinimo IS NULL OR @MontoMinimo < 0
        THROW 50053, N'El monto mínimo no puede ser negativo.', 1;
    IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaFin <= @FechaInicio
        THROW 50053, N'La vigencia no es válida: la fecha de fin debe ser posterior a la de inicio.', 1;
    IF @LimiteUsosTotal IS NOT NULL AND @LimiteUsosTotal <= 0
        THROW 50053, N'El límite total de usos debe ser mayor a cero.', 1;
    IF @LimiteUsosPorCliente IS NOT NULL AND @LimiteUsosPorCliente <= 0
        THROW 50053, N'El límite de usos por cliente debe ser mayor a cero.', 1;
    IF @IDCategoria IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE IDCategoria = @IDCategoria)
        THROW 50040, N'La categoría no existe.', 1;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Cupones_RegistrarUso
    @IDCupon        INT,
    @IDUsuario      INT,
    @IDPedido       INT,
    @MontoDescuento DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Filas INT, @Rechazo NVARCHAR(30), @Mensaje NVARCHAR(255), @Estado INT;

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        UPDATE dbo.Cupones
        SET    UsosActuales = UsosActuales + 1,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCupon = @IDCupon
          AND  Activo = 1
          AND  SYSUTCDATETIME() >= FechaInicio
          AND  SYSUTCDATETIME() <= FechaFin
          AND  (LimiteUsosTotal IS NULL OR UsosActuales < LimiteUsosTotal);

        SET @Filas = @@ROWCOUNT;

        IF @Filas = 0
        BEGIN
            SELECT @Rechazo = CASE
                        WHEN c.Activo = 0 THEN N'INACTIVO'
                        WHEN SYSUTCDATETIME() < c.FechaInicio THEN N'NO_VIGENTE'
                        WHEN SYSUTCDATETIME() > c.FechaFin THEN N'VENCIDO'
                        ELSE N'AGOTADO' END
            FROM   dbo.Cupones c
            WHERE  c.IDCupon = @IDCupon;

            IF @Rechazo IS NULL
                THROW 50091, N'El cupón no existe.', 1;

            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(@Rechazo) m;
            THROW 50095, @Mensaje, @Estado;
        END;

        IF EXISTS (
            SELECT 1
            FROM   dbo.Cupones c
            WHERE  c.IDCupon = @IDCupon
              AND  c.LimiteUsosPorCliente IS NOT NULL
              AND  (SELECT COUNT(*) FROM dbo.UsosCupones u
                    WHERE u.IDCupon = c.IDCupon AND u.IDUsuario = @IDUsuario AND u.Estado = N'APLICADO')
                   >= c.LimiteUsosPorCliente
        )
        BEGIN
            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(N'LIMITE_CLIENTE') m;
            THROW 50095, @Mensaje, @Estado;
        END;

        INSERT INTO dbo.UsosCupones (IDCupon, IDUsuario, IDPedido, MontoDescuento)
        VALUES (@IDCupon, @IDUsuario, @IDPedido, @MontoDescuento);

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Cupones_RevertirUso
    @IDPedido INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Revertidos TABLE (IDCupon INT NOT NULL);

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        UPDATE dbo.UsosCupones
        SET    Estado = N'REVERSADO', FechaReversion = SYSUTCDATETIME()
        OUTPUT inserted.IDCupon INTO @Revertidos (IDCupon)
        WHERE  IDPedido = @IDPedido AND Estado = N'APLICADO';

        UPDATE c
        SET    c.UsosActuales = CASE WHEN c.UsosActuales > 0 THEN c.UsosActuales - 1 ELSE 0 END,
               c.FechaActualizacion = SYSUTCDATETIME()
        FROM   dbo.Cupones c
        JOIN   @Revertidos r ON r.IDCupon = c.IDCupon;

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Crear
    @IDUsuarioActor       INT,
    @Codigo               NVARCHAR(30),
    @Descripcion          NVARCHAR(255) = NULL,
    @TipoDescuento        NVARCHAR(12),
    @Valor                DECIMAL(12,2),
    @IDCategoria          INT           = NULL,
    @MontoMinimo          DECIMAL(12,2) = 0,
    @FechaInicio          DATETIME2(0),
    @FechaFin             DATETIME2(0),
    @LimiteUsosTotal      INT           = NULL,
    @LimiteUsosPorCliente INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    SET @MontoMinimo = ISNULL(@MontoMinimo, 0);

    IF @Codigo IS NULL OR LEN(@Codigo) < 3 OR LEN(@Codigo) > 30
       OR @Codigo COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Z0-9_-]%'
        THROW 50053, N'El código debe tener de 3 a 30 caracteres: letras, números, guion o guion bajo.', 1;

    EXEC Interno.SP_Cupones_ValidarDatos
        @TipoDescuento = @TipoDescuento, @Valor = @Valor, @IDCategoria = @IDCategoria,
        @MontoMinimo = @MontoMinimo, @FechaInicio = @FechaInicio, @FechaFin = @FechaFin,
        @LimiteUsosTotal = @LimiteUsosTotal, @LimiteUsosPorCliente = @LimiteUsosPorCliente;

    DECLARE @IDCupon INT, @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Cupones WITH (UPDLOCK, HOLDLOCK) WHERE Codigo = @Codigo)
            THROW 50090, N'Ya existe un cupón con ese código.', 1;

        INSERT INTO dbo.Cupones
            (Codigo, Descripcion, TipoDescuento, Valor, IDCategoria, MontoMinimo,
             FechaInicio, FechaFin, LimiteUsosTotal, LimiteUsosPorCliente)
        VALUES
            (@Codigo, @Descripcion, @TipoDescuento, @Valor, @IDCategoria, @MontoMinimo,
             @FechaInicio, @FechaFin, @LimiteUsosTotal, @LimiteUsosPorCliente);

        SET @IDCupon = SCOPE_IDENTITY();

        SET @ValorNuevo = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50090, N'Ya existe un cupón con ese código.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Actualizar
    @IDUsuarioActor       INT,
    @IDCupon              INT,
    @Descripcion          NVARCHAR(255) = NULL,
    @TipoDescuento        NVARCHAR(12),
    @Valor                DECIMAL(12,2),
    @IDCategoria          INT           = NULL,
    @MontoMinimo          DECIMAL(12,2) = 0,
    @FechaInicio          DATETIME2(0),
    @FechaFin             DATETIME2(0),
    @LimiteUsosTotal      INT           = NULL,
    @LimiteUsosPorCliente INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    SET @MontoMinimo = ISNULL(@MontoMinimo, 0);

    EXEC Interno.SP_Cupones_ValidarDatos
        @TipoDescuento = @TipoDescuento, @Valor = @Valor, @IDCategoria = @IDCategoria,
        @MontoMinimo = @MontoMinimo, @FechaInicio = @FechaInicio, @FechaFin = @FechaFin,
        @LimiteUsosTotal = @LimiteUsosTotal, @LimiteUsosPorCliente = @LimiteUsosPorCliente;

    DECLARE @UsosActuales INT, @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @UsosActuales = UsosActuales
        FROM   dbo.Cupones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCupon = @IDCupon;

        IF @UsosActuales IS NULL
            THROW 50091, N'El cupón no existe.', 1;

        IF @LimiteUsosTotal IS NOT NULL AND @LimiteUsosTotal < @UsosActuales
            THROW 50093, N'El límite total de usos no puede ser menor a los usos ya registrados.', 1;

        SET @ValorAnterior = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Cupones
        SET    Descripcion = @Descripcion, TipoDescuento = @TipoDescuento, Valor = @Valor,
               IDCategoria = @IDCategoria, MontoMinimo = @MontoMinimo,
               FechaInicio = @FechaInicio, FechaFin = @FechaFin,
               LimiteUsosTotal = @LimiteUsosTotal, LimiteUsosPorCliente = @LimiteUsosPorCliente,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCupon = @IDCupon;

        SET @ValorNuevo = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_CambiarEstado
    @IDUsuarioActor INT,
    @IDCupon        INT,
    @Activo         BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    DECLARE @ActivoActual BIT, @Accion NVARCHAR(20),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ActivoActual = Activo
        FROM   dbo.Cupones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCupon = @IDCupon;

        IF @ActivoActual IS NULL
            THROW 50091, N'El cupón no existe.', 1;

        IF @ActivoActual = @Activo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDCupon AS IDCupon, @Activo AS Activo;
            RETURN;
        END;

        UPDATE dbo.Cupones
        SET    Activo = @Activo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCupon = @IDCupon;

        SET @Accion = CASE WHEN @Activo = 0 THEN N'DESACTIVAR' ELSE N'MODIFICAR' END;
        SET @ValorAnterior = (SELECT @ActivoActual AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Activo       AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = @Accion,
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon, @Activo AS Activo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Eliminar
    @IDUsuarioActor INT,
    @IDCupon        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    DECLARE @ValorAnterior NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SET @ValorAnterior = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WITH (UPDLOCK, HOLDLOCK)
            WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        IF @ValorAnterior IS NULL
            THROW 50091, N'El cupón no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.UsosCupones WHERE IDCupon = @IDCupon)
            THROW 50094, N'El cupón ya fue utilizado; desactívelo en lugar de eliminarlo.', 1;

        UPDATE dbo.Carritos SET IDCupon = NULL WHERE IDCupon = @IDCupon;
        DELETE FROM dbo.Cupones WHERE IDCupon = @IDCupon;

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = N'ELIMINAR', @ValorAnterior = @ValorAnterior;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_ObtenerPorID
    @IDUsuarioActor INT,
    @IDCupon        INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    SELECT  c.IDCupon, c.Codigo, c.Descripcion, c.TipoDescuento, c.Valor, c.IDCategoria, ca.Nombre AS Categoria,
            c.MontoMinimo, c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente,
            c.UsosActuales, c.Activo, c.FechaCreacion, c.FechaActualizacion
    FROM    dbo.Cupones c
    LEFT JOIN dbo.Categorias ca ON ca.IDCategoria = c.IDCategoria
    WHERE   c.IDCupon = @IDCupon;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Listar
    @IDUsuarioActor INT,
    @Busqueda       NVARCHAR(100) = NULL,
    @Estado         NVARCHAR(12)  = NULL,
    @IDCategoria    INT           = NULL,
    @OrdenarPor     NVARCHAR(20)  = N'FechaFin',   -- Codigo | FechaFin | UsosActuales | FechaCreacion
    @Direccion      NVARCHAR(4)   = N'DESC',       -- ASC | DESC
    @Pagina         INT           = 1,
    @TamanoPagina   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    ;WITH Datos AS (
        SELECT  c.IDCupon, c.Codigo, c.Descripcion, c.TipoDescuento, c.Valor, c.IDCategoria,
                ca.Nombre AS Categoria, c.MontoMinimo, c.FechaInicio, c.FechaFin,
                c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.UsosActuales, c.Activo, c.FechaCreacion,
                CASE
                    WHEN c.Activo = 0 THEN N'INACTIVO'
                    WHEN SYSUTCDATETIME() < c.FechaInicio THEN N'PROGRAMADO'
                    WHEN SYSUTCDATETIME() > c.FechaFin THEN N'VENCIDO'
                    WHEN c.LimiteUsosTotal IS NOT NULL AND c.UsosActuales >= c.LimiteUsosTotal THEN N'AGOTADO'
                    ELSE N'VIGENTE'
                END AS Estado
        FROM    dbo.Cupones c
        LEFT JOIN dbo.Categorias ca ON ca.IDCategoria = c.IDCategoria
        WHERE   (@IDCategoria IS NULL OR c.IDCategoria = @IDCategoria)
            AND (@Busqueda IS NULL
                 OR c.Codigo      LIKE N'%' + @Busqueda + N'%'
                 OR c.Descripcion LIKE N'%' + @Busqueda + N'%')
    )
    SELECT  d.*, COUNT(*) OVER () AS TotalRegistros
    FROM    Datos d
    WHERE   (@Estado IS NULL OR d.Estado = @Estado)
    ORDER BY
        CASE WHEN @OrdenarPor = N'Codigo'        AND @Direccion = N'ASC'  THEN d.Codigo        END ASC,
        CASE WHEN @OrdenarPor = N'Codigo'        AND @Direccion = N'DESC' THEN d.Codigo        END DESC,
        CASE WHEN @OrdenarPor = N'FechaFin'      AND @Direccion = N'ASC'  THEN d.FechaFin      END ASC,
        CASE WHEN @OrdenarPor = N'FechaFin'      AND @Direccion = N'DESC' THEN d.FechaFin      END DESC,
        CASE WHEN @OrdenarPor = N'UsosActuales'  AND @Direccion = N'ASC'  THEN d.UsosActuales  END ASC,
        CASE WHEN @OrdenarPor = N'UsosActuales'  AND @Direccion = N'DESC' THEN d.UsosActuales  END DESC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'ASC'  THEN d.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'DESC' THEN d.FechaCreacion END DESC,
        d.IDCupon DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_AplicarCupon
    @IDUsuario INT,
    @Codigo    NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    IF @Codigo IS NULL OR @Codigo = N''
        THROW 50053, N'Indique el código del cupón.', 1;

    DECLARE @IDCarrito INT, @IDCupon INT, @MontoMinimo DECIMAL(12,2),
            @Rechazo NVARCHAR(30), @Mensaje NVARCHAR(255), @Estado INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = NULL, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        SELECT @IDCupon = IDCupon, @MontoMinimo = MontoMinimo
        FROM   dbo.Cupones
        WHERE  Codigo = @Codigo;

        IF @IDCupon IS NULL
            THROW 50091, N'El cupón no existe.', 1;

        SELECT @Rechazo = CodigoRechazo
        FROM   dbo.FU_Cupones_CalculoDescuento(@IDCupon, @IDCarrito, @IDUsuario);

        IF @Rechazo IS NOT NULL
        BEGIN
            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(@Rechazo) m;
            IF @Rechazo = N'MINIMO_NO_ALCANZADO'
                SET @Mensaje = CONCAT(N'La compra mínima para este cupón es Q', CONVERT(NVARCHAR(30), @MontoMinimo), N'.');
            THROW 50095, @Mensaje, @Estado;
        END;

        UPDATE dbo.Carritos
        SET    IDCupon = @IDCupon, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCarrito = @IDCarrito;

        EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT  @IDCarrito AS IDCarrito, t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_QuitarCupon
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IDCarrito INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = NULL, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        UPDATE dbo.Carritos
        SET    IDCupon = NULL, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCarrito = @IDCarrito AND IDCupon IS NOT NULL;

        IF @@ROWCOUNT > 0
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT  @IDCarrito AS IDCarrito, t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
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

    SELECT  @IDCarrito AS IDCarrito,
            t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva, t.Lineas,
            cu.IDCupon,
            cu.Codigo AS CodigoCupon,
            t.CuponRechazo,
            CASE WHEN t.CuponRechazo = N'MINIMO_NO_ALCANZADO'
                 THEN CONCAT(N'La compra mínima para este cupón es Q', CONVERT(NVARCHAR(30), cu.MontoMinimo), N'.')
                 ELSE m.Mensaje END AS CuponMensaje
    FROM    dbo.FU_Carrito_Totales(@IDCarrito) t
    LEFT JOIN dbo.Cupones cu ON cu.IDCupon = t.IDCupon
    OUTER APPLY dbo.FU_Cupones_MensajeRechazo(t.CuponRechazo) m;

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

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'016_Cupones_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'016_Cupones_Procedimientos.sql');
GO