/* =============================================================================
   022_Gestion_Pedidos_Procedimientos.sql
   Módulo 7 - Avance de estado, cancelación, devoluciones y consultas de pedidos.
   Reejecutable (CREATE OR ALTER).

   Quién puede qué:
     Operador / Administrador (PEDIDOS_GESTIONAR): avanzar el estado (preparar,
       despachar, entregar), cancelar antes del despacho y registrar devoluciones.
     Cliente: consultar sus pedidos e historial y CANCELAR el suyo únicamente
       mientras esté PAGADO (antes de que se empiece a preparar).

   Cancelar o devolver reintegra la existencia con movimientos del kardex
   (CANCELACION / DEVOLUCION). Cancelar además libera el uso del cupón.
   Los SPs devuelven el monto a reembolsar: el reembolso a la pasarela lo
   ejecuta el backend.

   Reembolso de una devolución = precio x unidades - descuento del cupón
   prorrateado por unidades (el envío no se reembolsa). Se calcula de forma
   acumulada por línea, así la suma de devoluciones parciales es exacta.

    Códigos de error: ver el README (sección «Catálogo de códigos de error»).
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO
CREATE OR ALTER PROCEDURE Interno.SP_Pedidos_CambiarEstado
    @IDPedido    INT,
    @EstadoNuevo NVARCHAR(20),
    @IDUsuario   INT,
    @Comentario  NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @EstadoActual NVARCHAR(20), @Mensaje NVARCHAR(255),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    SET @Comentario = NULLIF(LTRIM(RTRIM(@Comentario)), N'');

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        SELECT @EstadoActual = Estado
        FROM   dbo.Pedidos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDPedido = @IDPedido;

        IF @EstadoActual IS NULL
            THROW 50103, N'El pedido no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.TransicionesEstadoPedido
                       WHERE EstadoOrigen = @EstadoActual AND EstadoDestino = @EstadoNuevo)
        BEGIN
            SET @Mensaje = CONCAT(N'Transición no permitida: de ', @EstadoActual, N' a ', @EstadoNuevo, N'.');
            THROW 50120, @Mensaje, 1;
        END;

        UPDATE dbo.Pedidos
        SET    Estado = @EstadoNuevo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDPedido = @IDPedido;

        INSERT INTO dbo.HistorialEstadosPedido (IDPedido, EstadoAnterior, EstadoNuevo, IDUsuario, Comentario)
        VALUES (@IDPedido, @EstadoActual, @EstadoNuevo, @IDUsuario, @Comentario);

        SET @ValorAnterior = (SELECT @EstadoActual AS Estado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @EstadoNuevo AS Estado, @Comentario AS Comentario FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuario, @Modulo = N'Pedidos', @Entidad = N'Pedido',
            @IDEntidad = @IDPedido, @Accion = N'CAMBIO_ESTADO',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_AvanzarEstado
    @IDUsuarioActor INT,
    @IDPedido       INT,
    @EstadoNuevo    NVARCHAR(20),
    @Comentario     NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'PEDIDOS_GESTIONAR';

    IF @EstadoNuevo IS NULL OR @EstadoNuevo NOT IN (N'EN_PREPARACION', N'DESPACHADO', N'ENTREGADO')
        THROW 50121, N'Este SP solo avanza a EN_PREPARACION, DESPACHADO o ENTREGADO; para cancelar o devolver use la operación correspondiente.', 1;

    DECLARE @EstadoActual NVARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @EstadoActual = Estado
        FROM   dbo.Pedidos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDPedido = @IDPedido;

        IF @EstadoActual IS NULL
            THROW 50103, N'El pedido no existe.', 1;

        IF @EstadoActual = @EstadoNuevo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDPedido AS IDPedido, @EstadoActual AS Estado, CAST(0 AS BIT) AS Cambio;
            RETURN;
        END;

        EXEC Interno.SP_Pedidos_CambiarEstado
            @IDPedido = @IDPedido, @EstadoNuevo = @EstadoNuevo, @IDUsuario = @IDUsuarioActor, @Comentario = @Comentario;

        COMMIT TRANSACTION;

        SELECT @IDPedido AS IDPedido, @EstadoNuevo AS Estado, CAST(1 AS BIT) AS Cambio;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_Cancelar
    @IDUsuarioActor INT,
    @IDPedido       INT,
    @Motivo         NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Motivo = LTRIM(RTRIM(@Motivo));
    IF @Motivo IS NULL OR @Motivo = N''
        THROW 50071, N'El motivo es obligatorio.', 1;

    DECLARE @EsGestor BIT = 0, @Dueno INT, @Estado NVARCHAR(20), @Numero NVARCHAR(20), @Total DECIMAL(18,2),
            @IDVariante INT = 0, @Cantidad INT, @MotivoKardex NVARCHAR(255);

    IF EXISTS (
        SELECT 1
        FROM dbo.Usuarios u
        JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
        JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
        WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1 AND p.Codigo = N'PEDIDOS_GESTIONAR')
        SET @EsGestor = 1;

    IF @EsGestor = 0
        EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'COMPRAR';

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT  @Dueno = IDUsuario, @Estado = Estado, @Numero = NumeroPedido, @Total = Total
        FROM    dbo.Pedidos WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDPedido = @IDPedido;

        IF @Dueno IS NULL OR (@Dueno <> @IDUsuarioActor AND @EsGestor = 0)
            THROW 50103, N'El pedido no existe.', 1;

        IF @Estado = N'CANCELADO'
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDPedido AS IDPedido, @Estado AS Estado, CAST(0 AS BIT) AS Cambio, CAST(0 AS DECIMAL(18,2)) AS MontoReembolso;
            RETURN;
        END;

        IF @EsGestor = 0 AND @Estado <> N'PAGADO'
            THROW 50122, N'Solo puede cancelar su pedido mientras esté PAGADO; si ya se está preparando, contacte a la tienda.', 1;

        EXEC Interno.SP_Pedidos_CambiarEstado
            @IDPedido = @IDPedido, @EstadoNuevo = N'CANCELADO', @IDUsuario = @IDUsuarioActor,
            @Comentario = @Motivo;

        SET @MotivoKardex = CONCAT(N'Cancelación del pedido ', @Numero, N': ', LEFT(@Motivo, 180));

        WHILE 1 = 1
        BEGIN
            SELECT TOP (1) @IDVariante = IDVariante, @Cantidad = Cantidad
            FROM   dbo.DetallePedidos
            WHERE  IDPedido = @IDPedido AND IDVariante > @IDVariante
            ORDER BY IDVariante;

            IF @@ROWCOUNT = 0 BREAK;

            EXEC Interno.SP_Inventario_AplicarMovimiento
                @IDVariante = @IDVariante, @TipoMovimiento = N'CANCELACION', @Cantidad = @Cantidad,
                @Motivo = @MotivoKardex, @IDUsuario = @IDUsuarioActor,
                @TipoReferencia = N'PEDIDO', @IDReferencia = @IDPedido;
        END;

        EXEC Interno.SP_Cupones_RevertirUso @IDPedido = @IDPedido;

        COMMIT TRANSACTION;

        SELECT @IDPedido AS IDPedido, N'CANCELADO' AS Estado, CAST(1 AS BIT) AS Cambio, @Total AS MontoReembolso;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_RegistrarDevolucion
    @IDUsuarioActor INT,
    @IDPedido       INT,
    @Motivo         NVARCHAR(255),
    @DevolverTodo   BIT           = 0,
    @Lineas         NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'PEDIDOS_GESTIONAR';

    SET @Motivo = LTRIM(RTRIM(@Motivo));
    SET @DevolverTodo = ISNULL(@DevolverTodo, 0);
    IF @Motivo IS NULL OR @Motivo = N''
        THROW 50071, N'El motivo es obligatorio.', 1;
    IF @DevolverTodo = 0 AND (@Lineas IS NULL OR ISJSON(@Lineas) <> 1)
        THROW 50125, N'Indique las líneas a devolver o solicite la devolución total.', 1;

    DECLARE @Estado NVARCHAR(20), @Numero NVARCHAR(20), @Falla NVARCHAR(400),
            @IDDevolucion INT, @MontoTotal DECIMAL(18,2), @Pendientes INT, @NuevoEstado NVARCHAR(20),
            @IDVariante INT = 0, @Cantidad INT, @MotivoKardex NVARCHAR(255),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX), @Comentario NVARCHAR(255);

    DECLARE @Crudo TABLE (IDDetallePedido INT NULL, Cantidad INT NULL);
    DECLARE @Solicitud TABLE (IDDetallePedido INT PRIMARY KEY, Cantidad INT NOT NULL);
    DECLARE @Calculo TABLE (
        IDDetallePedido INT PRIMARY KEY,
        IDVariante      INT           NOT NULL,
        SKU             NVARCHAR(50)  NOT NULL,
        Cantidad        INT           NOT NULL,
        PrecioUnitario  DECIMAL(12,2) NOT NULL,
        CantidadVendida INT           NOT NULL,
        DescuentoLinea  DECIMAL(18,2) NOT NULL,
        Devuelta        INT           NOT NULL,
        Reembolso       DECIMAL(18,2) NOT NULL DEFAULT 0
    );

    IF @DevolverTodo = 0
    BEGIN
        INSERT INTO @Crudo (IDDetallePedido, Cantidad)
        SELECT j.IDDetallePedido, j.Cantidad
        FROM OPENJSON(@Lineas) WITH (IDDetallePedido INT '$.idDetallePedido', Cantidad INT '$.cantidad') j;

        IF NOT EXISTS (SELECT 1 FROM @Crudo)
            THROW 50125, N'La lista de líneas a devolver está vacía.', 1;
        IF EXISTS (SELECT 1 FROM @Crudo WHERE IDDetallePedido IS NULL OR Cantidad IS NULL OR Cantidad <= 0)
            THROW 50125, N'Cada línea requiere idDetallePedido y una cantidad mayor a cero.', 1;

        INSERT INTO @Solicitud (IDDetallePedido, Cantidad)
        SELECT IDDetallePedido, SUM(Cantidad) FROM @Crudo GROUP BY IDDetallePedido;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT  @Estado = Estado, @Numero = NumeroPedido
        FROM    dbo.Pedidos WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDPedido = @IDPedido;

        IF @Estado IS NULL
            THROW 50103, N'El pedido no existe.', 1;
        IF @Estado NOT IN (N'ENTREGADO', N'DEVUELTO_PARCIAL')
            THROW 50123, N'Solo se pueden devolver pedidos entregados.', 1;

        IF @DevolverTodo = 1
            INSERT INTO @Solicitud (IDDetallePedido, Cantidad)
            SELECT IDDetallePedido, Cantidad - CantidadDevuelta
            FROM   dbo.DetallePedidos
            WHERE  IDPedido = @IDPedido AND Cantidad > CantidadDevuelta;

        IF EXISTS (SELECT 1 FROM @Solicitud s
                   LEFT JOIN dbo.DetallePedidos d WITH (UPDLOCK, HOLDLOCK)
                          ON d.IDDetallePedido = s.IDDetallePedido AND d.IDPedido = @IDPedido
                   WHERE d.IDDetallePedido IS NULL)
            THROW 50125, N'Alguna de las líneas no pertenece al pedido.', 1;

        INSERT INTO @Calculo (IDDetallePedido, IDVariante, SKU, Cantidad, PrecioUnitario, CantidadVendida, DescuentoLinea, Devuelta)
        SELECT  d.IDDetallePedido, d.IDVariante, d.SKU, s.Cantidad, d.PrecioUnitario, d.Cantidad, d.DescuentoLinea, d.CantidadDevuelta
        FROM    @Solicitud s
        JOIN    dbo.DetallePedidos d WITH (UPDLOCK, HOLDLOCK) ON d.IDDetallePedido = s.IDDetallePedido;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'No se puede devolver más de lo vendido en la línea del SKU ', SKU,
                                       N': quedan ', CantidadVendida - Devuelta, N' por devolver y se solicitan ', Cantidad, N'.')
        FROM   @Calculo
        WHERE  Cantidad > CantidadVendida - Devuelta
        ORDER BY IDDetallePedido;

        IF @Falla IS NOT NULL
            THROW 50124, @Falla, 1;

        UPDATE @Calculo
        SET    Reembolso =
                 ( CAST(Devuelta + Cantidad AS DECIMAL(18,2)) * PrecioUnitario
                   - CAST(ROUND(DescuentoLinea * (Devuelta + Cantidad) / CantidadVendida, 2) AS DECIMAL(18,2)) )
               - ( CAST(Devuelta AS DECIMAL(18,2)) * PrecioUnitario
                   - CAST(ROUND(DescuentoLinea * Devuelta / CantidadVendida, 2) AS DECIMAL(18,2)) );

        SELECT @MontoTotal = SUM(Reembolso) FROM @Calculo;

        INSERT INTO dbo.Devoluciones (IDPedido, IDUsuario, Motivo, MontoReembolso)
        VALUES (@IDPedido, @IDUsuarioActor, @Motivo, @MontoTotal);

        SET @IDDevolucion = SCOPE_IDENTITY();

        INSERT INTO dbo.DetalleDevoluciones (IDDevolucion, IDDetallePedido, Cantidad, MontoReembolso)
        SELECT @IDDevolucion, IDDetallePedido, Cantidad, Reembolso FROM @Calculo;

        UPDATE d
        SET    d.CantidadDevuelta = d.CantidadDevuelta + c.Cantidad
        FROM   dbo.DetallePedidos d
        JOIN   @Calculo c ON c.IDDetallePedido = d.IDDetallePedido;

        SET @MotivoKardex = CONCAT(N'Devolución del pedido ', @Numero, N': ', LEFT(@Motivo, 180));

        WHILE 1 = 1
        BEGIN
            SELECT TOP (1) @IDVariante = IDVariante, @Cantidad = Cantidad
            FROM   @Calculo
            WHERE  IDVariante > @IDVariante
            ORDER BY IDVariante;

            IF @@ROWCOUNT = 0 BREAK;

            EXEC Interno.SP_Inventario_AplicarMovimiento
                @IDVariante = @IDVariante, @TipoMovimiento = N'DEVOLUCION', @Cantidad = @Cantidad,
                @Motivo = @MotivoKardex, @IDUsuario = @IDUsuarioActor,
                @TipoReferencia = N'DEVOLUCION', @IDReferencia = @IDDevolucion;
        END;

        SELECT @Pendientes = SUM(Cantidad - CantidadDevuelta) FROM dbo.DetallePedidos WHERE IDPedido = @IDPedido;
        SET @NuevoEstado = CASE WHEN @Pendientes = 0 THEN N'DEVUELTO' ELSE N'DEVUELTO_PARCIAL' END;
        SET @Comentario = CONCAT(N'Devolución #', @IDDevolucion, N': ', LEFT(@Motivo, 200));

        IF @NuevoEstado <> @Estado
        BEGIN
            EXEC Interno.SP_Pedidos_CambiarEstado
                @IDPedido = @IDPedido, @EstadoNuevo = @NuevoEstado, @IDUsuario = @IDUsuarioActor, @Comentario = @Comentario;
        END
        ELSE
        BEGIN

            INSERT INTO dbo.HistorialEstadosPedido (IDPedido, EstadoAnterior, EstadoNuevo, IDUsuario, Comentario)
            VALUES (@IDPedido, @Estado, @NuevoEstado, @IDUsuarioActor, @Comentario);

            SET @ValorAnterior = (SELECT @Estado AS Estado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
            SET @ValorNuevo    = (SELECT @NuevoEstado AS Estado, @Comentario AS Comentario FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

            EXEC dbo.SP_Bitacora_Registrar
                @IDUsuario = @IDUsuarioActor, @Modulo = N'Pedidos', @Entidad = N'Pedido',
                @IDEntidad = @IDPedido, @Accion = N'CAMBIO_ESTADO',
                @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;
        END;

        COMMIT TRANSACTION;

        SELECT @IDDevolucion AS IDDevolucion, @IDPedido AS IDPedido, @NuevoEstado AS EstadoPedido,
               @MontoTotal AS MontoReembolso;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_ListarMios
    @IDUsuario    INT,
    @Estado       NVARCHAR(20) = NULL,
    @Pagina       INT          = 1,
    @TamanoPagina INT          = 10
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 10;
    IF @TamanoPagina > 50 SET @TamanoPagina = 50;

    SELECT  p.IDPedido, p.NumeroPedido, p.Estado, p.Total, p.FechaCreacion, p.FechaActualizacion,
            (SELECT SUM(d.Cantidad) FROM dbo.DetallePedidos d WHERE d.IDPedido = p.IDPedido) AS Unidades,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.Pedidos p
    WHERE   p.IDUsuario = @IDUsuario
        AND (@Estado IS NULL OR p.Estado = @Estado)
    ORDER BY p.FechaCreacion DESC, p.IDPedido DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_ListarTransiciones
AS
BEGIN
    SET NOCOUNT ON;

    SELECT EstadoOrigen, EstadoDestino
    FROM   dbo.TransicionesEstadoPedido
    ORDER BY EstadoOrigen, EstadoDestino;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_ObtenerDetalle
    @IDUsuarioActor INT,
    @IDPedido       INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Dueno INT, @VerTodo BIT = 0;

    SELECT @Dueno = IDUsuario FROM dbo.Pedidos WHERE IDPedido = @IDPedido;

    IF EXISTS (
        SELECT 1
        FROM dbo.Usuarios u
        JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
        JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
        WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1 AND p.Codigo = N'PEDIDOS_GESTIONAR')
        SET @VerTodo = 1;

    IF @Dueno IS NULL OR (@Dueno <> @IDUsuarioActor AND @VerTodo = 0)
        THROW 50103, N'El pedido no existe.', 1;

    SELECT  p.IDPedido, p.NumeroPedido, p.Estado, p.IDUsuario,
            u.Correo AS CorreoCliente, CONCAT(u.Nombres, N' ', u.Apellidos) AS NombreCliente,
            p.Subtotal, p.Descuento, p.CostoEnvio, p.Total, p.BaseImponible, p.Iva, p.CodigoCupon,
            p.NombreEnvio, p.DestinatarioEnvio, p.TelefonoEnvio, p.DepartamentoEnvio, p.MunicipioEnvio,
            p.DireccionEnvio, p.ReferenciaEnvio, p.FechaCreacion, p.FechaActualizacion
    FROM    dbo.Pedidos p
    JOIN    dbo.Usuarios u ON u.IDUsuario = p.IDUsuario
    WHERE   p.IDPedido = @IDPedido;

    SELECT  d.IDDetallePedido, d.IDVariante, d.SKU, d.NombreProducto, d.Atributos, d.PrecioUnitario,
            d.Cantidad, d.Subtotal, d.DescuentoLinea, d.CantidadDevuelta
    FROM    dbo.DetallePedidos d
    WHERE   d.IDPedido = @IDPedido
    ORDER BY d.IDDetallePedido;

    SELECT  h.IDHistorial, h.EstadoAnterior, h.EstadoNuevo, h.Fecha, h.Comentario,
            h.IDUsuario, u.Correo AS CorreoUsuario
    FROM    dbo.HistorialEstadosPedido h
    JOIN    dbo.Usuarios u ON u.IDUsuario = h.IDUsuario
    WHERE   h.IDPedido = @IDPedido
    ORDER BY h.IDHistorial;

    SELECT  dv.IDDevolucion, dv.Fecha, dv.Motivo, dv.MontoReembolso, u.Correo AS CorreoUsuario
    FROM    dbo.Devoluciones dv
    JOIN    dbo.Usuarios u ON u.IDUsuario = dv.IDUsuario
    WHERE   dv.IDPedido = @IDPedido
    ORDER BY dv.IDDevolucion;

    SELECT  dd.IDDevolucion, dd.IDDetallePedido, d.SKU, d.NombreProducto, dd.Cantidad, dd.MontoReembolso
    FROM    dbo.DetalleDevoluciones dd
    JOIN    dbo.DetallePedidos d ON d.IDDetallePedido = dd.IDDetallePedido
    WHERE   d.IDPedido = @IDPedido
    ORDER BY dd.IDDevolucion, dd.IDDetallePedido;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Checkout_ExpirarPagos
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET    p.Estado = N'EXPIRADO',
           p.Motivo = N'La reserva venció antes de completar el pago.',
           p.FechaActualizacion = SYSUTCDATETIME()
    FROM   dbo.Pagos p
    JOIN   dbo.Reservas r ON r.IDReserva = p.IDReserva
    WHERE  p.Estado = N'INICIADO'
      AND  (r.Estado IN (N'LIBERADA', N'VENCIDA')
            OR (r.Estado = N'ACTIVA' AND r.FechaVencimiento <= SYSUTCDATETIME()));

    SELECT @@ROWCOUNT AS PagosExpirados;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'023_Gestion_Pedidos_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'023_Gestion_Pedidos_Procedimientos.sql');
GO