/* =============================================================================
   020_Checkout_Procedimientos.sql
   Módulo 6 - Direcciones, envíos, checkout y pago, creación atómica del pedido.
   Reejecutable (CREATE OR ALTER).

   FLUJO DE PAGO (el backend orquesta; la pasarela es simulada pero recibe la
   misma clave de idempotencia):
     1) SP_Checkout_IniciarPago   valida carrito, dirección, envío y cupón;
                                  RESERVA la existencia 15 minutos y registra el
                                  pago INICIADO con la clave de idempotencia.
     2) El backend cobra en la pasarela (usando la misma clave).
     3a) Aprobado  -> SP_Pedidos_CrearPedido  crea, en UNA transacción, el pedido,
                      su detalle congelado, las SALIDAS del kardex, el uso del
                      cupón, la conversión del carrito y el pago APROBADO.
     3b) Rechazado -> SP_Checkout_RechazarPago libera la reserva.
   Todos son idempotentes: repetir la misma solicitud (doble clic o reintento
   por falla de red) devuelve el mismo resultado sin crear otro pedido ni cobro.

   Estados del pago: INICIADO | APROBADO | RECHAZADO | EXPIRADO | ANULADO.
   ANULADO = el cobro se aprobó pero no fue posible completar el pedido (reserva
   vencida, cupón agotado, cambio de precio...): el backend DEBE reembolsar.

   Códigos de error personalizados (THROW):
     50100 Dirección no encontrada                                  -> 404
     50101 Método de envío inválido                                 -> 400
     50102 El carrito está vacío                                    -> 409
     50103 Pedido no encontrado                                     -> 404
     50110 El total cambió desde que el cliente lo vio              -> 409
     50111 Clave de idempotencia reutilizada con datos distintos    -> 422
     50112 Solicitud de pago duplicada en proceso                   -> 409
     50113 El pago no existe                                        -> 404
     50114 No fue posible completar el pedido (se anula el pago)    -> 409
     50115 Los pedidos no se eliminan                               -> 500
     50116 Montos y datos de envío congelados                       -> 500
     50117 Historial de estados inmutable                           -> 500
   Reutiliza: 50053, 50067, 50068, 50070, 50081, 50095.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Direcciones_Crear
    @IDUsuario          INT,
    @NombreDestinatario NVARCHAR(100),
    @Telefono           NVARCHAR(20),
    @Departamento       NVARCHAR(50),
    @Municipio          NVARCHAR(50),
    @Direccion          NVARCHAR(250),
    @Referencia         NVARCHAR(250) = NULL,
    @EsPredeterminada   BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @NombreDestinatario = LTRIM(RTRIM(@NombreDestinatario));
    SET @Telefono = LTRIM(RTRIM(@Telefono));
    SET @Departamento = LTRIM(RTRIM(@Departamento));
    SET @Municipio = LTRIM(RTRIM(@Municipio));
    SET @Direccion = LTRIM(RTRIM(@Direccion));
    SET @Referencia = NULLIF(LTRIM(RTRIM(@Referencia)), N'');
    SET @EsPredeterminada = ISNULL(@EsPredeterminada, 0);

    IF ISNULL(@NombreDestinatario, N'') = N'' OR ISNULL(@Telefono, N'') = N'' OR ISNULL(@Departamento, N'') = N''
       OR ISNULL(@Municipio, N'') = N'' OR ISNULL(@Direccion, N'') = N''
        THROW 50053, N'Destinatario, teléfono, departamento, municipio y dirección son obligatorios.', 1;

    DECLARE @IDDireccion INT, @Existentes INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Existentes = COUNT(*)
        FROM   dbo.Direcciones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDUsuario = @IDUsuario AND Activo = 1;

        IF @Existentes >= 20
            THROW 50053, N'Solo se pueden guardar hasta 20 direcciones.', 1;
        IF @Existentes = 0
            SET @EsPredeterminada = 1;

        IF @EsPredeterminada = 1
            UPDATE dbo.Direcciones
            SET    EsPredeterminada = 0, FechaActualizacion = SYSUTCDATETIME()
            WHERE  IDUsuario = @IDUsuario AND EsPredeterminada = 1;

        INSERT INTO dbo.Direcciones
            (IDUsuario, NombreDestinatario, Telefono, Departamento, Municipio, Direccion, Referencia, EsPredeterminada)
        VALUES
            (@IDUsuario, @NombreDestinatario, @Telefono, @Departamento, @Municipio, @Direccion, @Referencia, @EsPredeterminada);

        SET @IDDireccion = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT @IDDireccion AS IDDireccion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Direcciones_Actualizar
    @IDUsuario          INT,
    @IDDireccion        INT,
    @NombreDestinatario NVARCHAR(100),
    @Telefono           NVARCHAR(20),
    @Departamento       NVARCHAR(50),
    @Municipio          NVARCHAR(50),
    @Direccion          NVARCHAR(250),
    @Referencia         NVARCHAR(250) = NULL,
    @EsPredeterminada   BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @NombreDestinatario = LTRIM(RTRIM(@NombreDestinatario));
    SET @Telefono = LTRIM(RTRIM(@Telefono));
    SET @Departamento = LTRIM(RTRIM(@Departamento));
    SET @Municipio = LTRIM(RTRIM(@Municipio));
    SET @Direccion = LTRIM(RTRIM(@Direccion));
    SET @Referencia = NULLIF(LTRIM(RTRIM(@Referencia)), N'');
    SET @EsPredeterminada = ISNULL(@EsPredeterminada, 0);

    IF ISNULL(@NombreDestinatario, N'') = N'' OR ISNULL(@Telefono, N'') = N'' OR ISNULL(@Departamento, N'') = N''
       OR ISNULL(@Municipio, N'') = N'' OR ISNULL(@Direccion, N'') = N''
        THROW 50053, N'Destinatario, teléfono, departamento, municipio y dirección son obligatorios.', 1;

    DECLARE @Existe INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Existe = IDDireccion
        FROM   dbo.Direcciones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDDireccion = @IDDireccion AND IDUsuario = @IDUsuario AND Activo = 1;

        IF @Existe IS NULL
            THROW 50100, N'La dirección no existe.', 1;

        IF @EsPredeterminada = 1
            UPDATE dbo.Direcciones
            SET    EsPredeterminada = 0, FechaActualizacion = SYSUTCDATETIME()
            WHERE  IDUsuario = @IDUsuario AND EsPredeterminada = 1 AND IDDireccion <> @IDDireccion;

        UPDATE dbo.Direcciones
        SET    NombreDestinatario = @NombreDestinatario, Telefono = @Telefono, Departamento = @Departamento,
               Municipio = @Municipio, Direccion = @Direccion, Referencia = @Referencia,
               EsPredeterminada = CASE WHEN @EsPredeterminada = 1 THEN 1 ELSE EsPredeterminada END,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDDireccion = @IDDireccion AND IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDDireccion AS IDDireccion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Direcciones_Eliminar
    @IDUsuario   INT,
    @IDDireccion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    DECLARE @EraPredeterminada BIT, @IDNueva INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @EraPredeterminada = EsPredeterminada
        FROM   dbo.Direcciones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDDireccion = @IDDireccion AND IDUsuario = @IDUsuario AND Activo = 1;

        IF @EraPredeterminada IS NULL
            THROW 50100, N'La dirección no existe.', 1;

        UPDATE dbo.Direcciones
        SET    Activo = 0, EsPredeterminada = 0, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDDireccion = @IDDireccion AND IDUsuario = @IDUsuario;

        IF @EraPredeterminada = 1
        BEGIN
            SELECT TOP (1) @IDNueva = IDDireccion
            FROM   dbo.Direcciones
            WHERE  IDUsuario = @IDUsuario AND Activo = 1
            ORDER BY FechaActualizacion DESC, IDDireccion DESC;

            IF @IDNueva IS NOT NULL
                UPDATE dbo.Direcciones SET EsPredeterminada = 1 WHERE IDDireccion = @IDNueva;
        END;

        COMMIT TRANSACTION;

        SELECT @IDDireccion AS IDDireccion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Direcciones_Listar
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SELECT  IDDireccion, NombreDestinatario, Telefono, Departamento, Municipio, Direccion, Referencia, EsPredeterminada
    FROM    dbo.Direcciones
    WHERE   IDUsuario = @IDUsuario AND Activo = 1
    ORDER BY EsPredeterminada DESC, FechaCreacion DESC, IDDireccion DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Envios_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IDMetodoEnvio, Nombre, Descripcion, Costo, DiasEstimados
    FROM   dbo.MetodosEnvio
    WHERE  Activo = 1
    ORDER BY Costo, IDMetodoEnvio;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Inventario_ReservarExistencia
    @IDUsuarioActor   INT,
    @Items            NVARCHAR(MAX),
    @DevolverResultado BIT          = 1,
    @IDReserva        INT           = NULL OUTPUT,
    @FechaVencimiento DATETIME2(0)  = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'COMPRAR';

    IF @Items IS NULL OR ISJSON(@Items) <> 1
        THROW 50053, N'La lista de productos a reservar no es un JSON válido.', 1;

    SET @IDReserva = NULL;
    SET @FechaVencimiento = NULL;

    DECLARE @MinutosVigencia INT = 15;
    DECLARE @Vencimiento DATETIME2(0), @Falla NVARCHAR(400),
            @IDPrevia INT, @IDVencida INT = 0, @Filas INT, @Total INT;

    DECLARE @Crudo TABLE (IDVariante INT NULL, Cantidad INT NULL);
    DECLARE @Solicitud TABLE (IDVariante INT NOT NULL PRIMARY KEY, Cantidad INT NOT NULL);

    INSERT INTO @Crudo (IDVariante, Cantidad)
    SELECT j.IDVariante, j.Cantidad
    FROM OPENJSON(@Items) WITH (IDVariante INT '$.idVariante', Cantidad INT '$.cantidad') j;

    IF NOT EXISTS (SELECT 1 FROM @Crudo)
        THROW 50053, N'La lista de productos a reservar está vacía.', 1;
    IF EXISTS (SELECT 1 FROM @Crudo WHERE IDVariante IS NULL OR Cantidad IS NULL OR Cantidad <= 0)
        THROW 50066, N'Cada producto requiere idVariante y una cantidad mayor a cero.', 1;

    INSERT INTO @Solicitud (IDVariante, Cantidad)
    SELECT IDVariante, SUM(Cantidad) FROM @Crudo GROUP BY IDVariante;

    SELECT @Total = COUNT(*) FROM @Solicitud;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IDPrevia = IDReserva
        FROM   dbo.Reservas WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDUsuario = @IDUsuarioActor AND Estado = N'ACTIVA';

        IF @IDPrevia IS NOT NULL
            EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDPrevia, @NuevoEstado = N'LIBERADA';

        WHILE 1 = 1
        BEGIN
            SELECT TOP (1) @IDVencida = r.IDReserva
            FROM   dbo.Reservas r
            WHERE  r.Estado = N'ACTIVA'
              AND  r.FechaVencimiento <= SYSUTCDATETIME()
              AND  r.IDReserva > @IDVencida
              AND  EXISTS (SELECT 1 FROM dbo.ReservasDetalle d
                           JOIN @Solicitud s ON s.IDVariante = d.IDVariante
                           WHERE d.IDReserva = r.IDReserva)
            ORDER BY r.IDReserva;

            IF @@ROWCOUNT = 0 BREAK;

            EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDVencida, @NuevoEstado = N'VENCIDA';
        END;

        IF EXISTS (SELECT 1 FROM @Solicitud s
                   LEFT JOIN dbo.Variantes v WITH (UPDLOCK) ON v.IDVariante = s.IDVariante
                   WHERE v.IDVariante IS NULL)
            THROW 50057, N'Alguno de los productos solicitados no existe.', 1;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' no está disponible para la venta.')
        FROM   @Solicitud s
        JOIN   dbo.Variantes v WITH (UPDLOCK) ON v.IDVariante = s.IDVariante
        JOIN   dbo.Productos p ON p.IDProducto = v.IDProducto
        JOIN   dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE  v.Activo = 0 OR p.Activo = 0 OR c.Activo = 0
        ORDER BY v.IDVariante;

        IF @Falla IS NOT NULL
            THROW 50068, @Falla, 1;

        SELECT TOP (1) @Falla = CONCAT(N'Existencias insuficientes para el SKU ', v.SKU,
                                       N': solicita ', s.Cantidad, N' y hay ', v.ExistenciaDisponible, N' disponible(s).')
        FROM   @Solicitud s
        JOIN   dbo.Variantes v WITH (UPDLOCK) ON v.IDVariante = s.IDVariante
        WHERE  v.ExistenciaDisponible < s.Cantidad
        ORDER BY v.IDVariante;

        IF @Falla IS NOT NULL
            THROW 50067, @Falla, 1;

        UPDATE v
        SET    v.ExistenciaReservada = v.ExistenciaReservada + s.Cantidad
        FROM   dbo.Variantes v
        JOIN   @Solicitud s ON s.IDVariante = v.IDVariante
        WHERE  v.ExistenciaDisponible >= s.Cantidad;

        SET @Filas = @@ROWCOUNT;
        IF @Filas <> @Total
            THROW 50067, N'No hay existencias suficientes para completar la reserva.', 1;

        SET @Vencimiento = DATEADD(MINUTE, @MinutosVigencia, SYSUTCDATETIME());

        INSERT INTO dbo.Reservas (IDUsuario, FechaVencimiento) VALUES (@IDUsuarioActor, @Vencimiento);
        SET @IDReserva = SCOPE_IDENTITY();

        INSERT INTO dbo.ReservasDetalle (IDReserva, IDVariante, Cantidad)
        SELECT @IDReserva, IDVariante, Cantidad FROM @Solicitud;

        COMMIT TRANSACTION;

        SET @FechaVencimiento = @Vencimiento;

        IF @DevolverResultado = 1
            SELECT @IDReserva AS IDReserva, @Vencimiento AS FechaVencimiento;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627) AND ERROR_MESSAGE() LIKE N'%UX_Reservas_UsuarioActiva%'
            THROW 50072, N'Ya hay un proceso de pago en curso; intente de nuevo en unos segundos.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Checkout_IniciarPago
    @IDUsuario         INT,
    @ClaveIdempotencia NVARCHAR(64),
    @IDDireccion       INT,
    @IDMetodoEnvio     INT,
    @TotalEsperado     DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @ClaveIdempotencia = LTRIM(RTRIM(@ClaveIdempotencia));
    IF @ClaveIdempotencia IS NULL OR LEN(@ClaveIdempotencia) < 8 OR LEN(@ClaveIdempotencia) > 64
       OR @ClaveIdempotencia COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_-]%'
        THROW 50053, N'La clave de idempotencia debe tener de 8 a 64 caracteres (letras, números, guion o guion bajo).', 1;

    DECLARE @IDCarrito INT, @IDPago INT, @EstadoPago NVARCHAR(12), @IDPedidoPago INT, @MontoPago DECIMAL(18,2),
            @IDReservaPago INT, @DirPago INT, @EnvioPago INT, @VenceExistente DATETIME2(0),
            @IDDireccionOk INT, @CostoEnvio DECIMAL(12,2),
            @Subtotal DECIMAL(18,2), @Descuento DECIMAL(18,2), @Total DECIMAL(18,2), @CuponRechazo NVARCHAR(30),
            @Falla NVARCHAR(400), @Mensaje NVARCHAR(255), @Estado INT,
            @IDReserva INT, @Vence DATETIME2(0), @Items NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = NULL, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        SELECT  @IDPago = IDPago, @EstadoPago = Estado, @IDPedidoPago = IDPedido, @MontoPago = Monto,
                @IDReservaPago = IDReserva, @DirPago = IDDireccion, @EnvioPago = IDMetodoEnvio
        FROM    dbo.Pagos WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia;

        IF @IDPago IS NOT NULL
        BEGIN
            IF @DirPago <> @IDDireccion OR @EnvioPago <> @IDMetodoEnvio
                THROW 50111, N'La clave de idempotencia ya se usó con datos distintos.', 1;

            IF @EstadoPago = N'INICIADO'
               AND NOT EXISTS (SELECT 1 FROM dbo.Reservas
                               WHERE IDReserva = @IDReservaPago AND Estado = N'ACTIVA' AND FechaVencimiento > SYSUTCDATETIME())
            BEGIN
                UPDATE dbo.Pagos
                SET    Estado = N'EXPIRADO', Motivo = N'La reserva venció antes de completar el pago.',
                       FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDPago = @IDPago;

                SET @EstadoPago = N'EXPIRADO';
            END;

            SELECT @VenceExistente = FechaVencimiento FROM dbo.Reservas WHERE IDReserva = @IDReservaPago;

            COMMIT TRANSACTION;

            SELECT  @IDPago AS IDPago, @EstadoPago AS Estado, CAST(0 AS BIT) AS Nuevo, @IDPedidoPago AS IDPedido,
                    @IDReservaPago AS IDReserva, @VenceExistente AS FechaVencimiento, @MontoPago AS Total;
            RETURN;
        END;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        SELECT @IDDireccionOk = IDDireccion
        FROM   dbo.Direcciones
        WHERE  IDDireccion = @IDDireccion AND IDUsuario = @IDUsuario AND Activo = 1;

        IF @IDDireccionOk IS NULL
            THROW 50100, N'La dirección de entrega no existe.', 1;

        SELECT @CostoEnvio = Costo
        FROM   dbo.MetodosEnvio
        WHERE  IDMetodoEnvio = @IDMetodoEnvio AND Activo = 1;

        IF @CostoEnvio IS NULL
            THROW 50101, N'El método de envío no es válido.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.CarritosDetalle WHERE IDCarrito = @IDCarrito)
            THROW 50102, N'El carrito está vacío.', 1;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' ya no está disponible para la venta.')
        FROM   dbo.CarritosDetalle d
        JOIN   dbo.Variantes v  ON v.IDVariante = d.IDVariante
        JOIN   dbo.Productos p  ON p.IDProducto = v.IDProducto
        JOIN   dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE  d.IDCarrito = @IDCarrito AND (v.Activo = 0 OR p.Activo = 0 OR c.Activo = 0)
        ORDER BY v.IDVariante;

        IF @Falla IS NOT NULL
            THROW 50068, @Falla, 1;

        SELECT  @Subtotal = t.Subtotal, @Descuento = t.Descuento, @CuponRechazo = t.CuponRechazo
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;

        IF @CuponRechazo IS NOT NULL
        BEGIN
            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(@CuponRechazo) m;
            THROW 50095, @Mensaje, @Estado;
        END;

        SET @Total = @Subtotal - @Descuento + @CostoEnvio;

        IF @TotalEsperado IS NOT NULL AND @TotalEsperado <> @Total
        BEGIN
            SET @Mensaje = CONCAT(N'El total cambió a Q', CONVERT(NVARCHAR(30), @Total), N'. Revise su pedido antes de pagar.');
            THROW 50110, @Mensaje, 1;
        END;

        SET @Items = (
            SELECT d.IDVariante AS idVariante, d.Cantidad AS cantidad
            FROM   dbo.CarritosDetalle d
            WHERE  d.IDCarrito = @IDCarrito
            ORDER BY d.IDVariante
            FOR JSON PATH
        );

        EXEC dbo.SP_Inventario_ReservarExistencia
            @IDUsuarioActor = @IDUsuario, @Items = @Items, @DevolverResultado = 0,
            @IDReserva = @IDReserva OUTPUT, @FechaVencimiento = @Vence OUTPUT;

        INSERT INTO dbo.Pagos (IDUsuario, ClaveIdempotencia, IDCarrito, IDReserva, IDDireccion, IDMetodoEnvio, Monto)
        VALUES (@IDUsuario, @ClaveIdempotencia, @IDCarrito, @IDReserva, @IDDireccion, @IDMetodoEnvio, @Total);

        SET @IDPago = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT  @IDPago AS IDPago, N'INICIADO' AS Estado, CAST(1 AS BIT) AS Nuevo, CAST(NULL AS INT) AS IDPedido,
                @IDReserva AS IDReserva, @Vence AS FechaVencimiento, @Total AS Total;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627) AND ERROR_MESSAGE() LIKE N'%UX_Pagos_Clave%'
            THROW 50112, N'Ya hay una solicitud de pago idéntica en proceso.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_CrearPedido
    @IDUsuario          INT,
    @ClaveIdempotencia  NVARCHAR(64),
    @ReferenciaPasarela NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @ClaveIdempotencia = LTRIM(RTRIM(@ClaveIdempotencia));
    SET @ReferenciaPasarela = NULLIF(LTRIM(RTRIM(@ReferenciaPasarela)), N'');
    IF @ClaveIdempotencia IS NULL OR LEN(@ClaveIdempotencia) < 8 OR LEN(@ClaveIdempotencia) > 64
       OR @ClaveIdempotencia COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_-]%'
        THROW 50053, N'La clave de idempotencia no es válida.', 1;

    DECLARE @IDCarrito INT, @IDPago INT, @EstadoPago NVARCHAR(12), @IDPedidoPago INT, @MotivoPago NVARCHAR(255),
            @IDReserva INT, @IDDireccion INT, @IDMetodoEnvio INT, @MontoPago DECIMAL(18,2),
            @EstadoCarrito NVARCHAR(12), @IDCupon INT, @CategoriaCupon INT, @CuponRechazo NVARCHAR(30),
            @Subtotal DECIMAL(18,2), @Descuento DECIMAL(18,2), @CostoEnvio DECIMAL(12,2), @NombreEnvio NVARCHAR(50),
            @Total DECIMAL(18,2), @Base DECIMAL(18,2), @Iva DECIMAL(18,2),
            @Falla NVARCHAR(400), @IDPedido INT, @FilasPedido INT,
            @SubElegible DECIMAL(18,2), @Residuo DECIMAL(18,2), @ValorNuevo NVARCHAR(MAX);

    DECLARE @Lineas TABLE (
        IDVariante     INT PRIMARY KEY,
        SKU            NVARCHAR(50)  NOT NULL,
        NombreProducto NVARCHAR(150) NOT NULL,
        Atributos      NVARCHAR(250) NULL,
        PrecioUnitario DECIMAL(12,2) NOT NULL,
        Cantidad       INT           NOT NULL,
        Subtotal       DECIMAL(18,2) NOT NULL,
        Elegible       BIT           NOT NULL,
        DescuentoLinea DECIMAL(18,2) NOT NULL DEFAULT 0
    );

    SELECT @IDCarrito = IDCarrito
    FROM   dbo.Pagos
    WHERE  IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia;

    IF @IDCarrito IS NULL
        THROW 50113, N'El pago no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @EstadoCarrito = Estado, @IDCupon = IDCupon
        FROM   dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCarrito = @IDCarrito;

        SELECT  @IDPago = IDPago, @EstadoPago = Estado, @IDPedidoPago = IDPedido, @MotivoPago = Motivo,
                @IDReserva = IDReserva, @IDDireccion = IDDireccion, @IDMetodoEnvio = IDMetodoEnvio, @MontoPago = Monto
        FROM    dbo.Pagos WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia;

        IF @EstadoPago <> N'INICIADO'
        BEGIN
            COMMIT TRANSACTION;

            SELECT  @IDPago AS IDPago, @EstadoPago AS Estado, CAST(0 AS BIT) AS Nuevo, @IDPedidoPago AS IDPedido,
                    (SELECT NumeroPedido FROM dbo.Pedidos WHERE IDPedido = @IDPedidoPago) AS NumeroPedido,
                    @MontoPago AS Total, @MotivoPago AS Motivo;
            RETURN;
        END;

        IF @EstadoCarrito <> N'ACTIVO'
            THROW 50114, N'El carrito cambió antes de confirmar el pago.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Reservas
                       WHERE IDReserva = @IDReserva AND Estado = N'ACTIVA' AND FechaVencimiento > SYSUTCDATETIME())
            THROW 50114, N'La reserva de existencias venció antes de confirmar el pago.', 1;

        SELECT  @Subtotal = t.Subtotal, @Descuento = t.Descuento, @CuponRechazo = t.CuponRechazo
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;

        SELECT  @CostoEnvio = Costo, @NombreEnvio = Nombre
        FROM    dbo.MetodosEnvio
        WHERE   IDMetodoEnvio = @IDMetodoEnvio;

        IF @CuponRechazo IS NOT NULL
            THROW 50114, N'El cupón dejó de ser aplicable antes de confirmar el pago.', 1;

        SET @Total = @Subtotal - @Descuento + @CostoEnvio;

        IF @Total <> @MontoPago
            THROW 50114, N'El total cambió después de iniciar el pago (precios o costo de envío).', 1;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' dejó de estar disponible para la venta.')
        FROM   dbo.CarritosDetalle d
        JOIN   dbo.Variantes v  ON v.IDVariante = d.IDVariante
        JOIN   dbo.Productos p  ON p.IDProducto = v.IDProducto
        JOIN   dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE  d.IDCarrito = @IDCarrito AND (v.Activo = 0 OR p.Activo = 0 OR c.Activo = 0)
        ORDER BY v.IDVariante;

        IF @Falla IS NOT NULL
            THROW 50114, @Falla, 1;

        SET @Base = CAST(ROUND(@Total / 1.12, 2) AS DECIMAL(18,2));
        SET @Iva  = @Total - @Base;

        IF @IDCupon IS NOT NULL
            SELECT @CategoriaCupon = IDCategoria FROM dbo.Cupones WHERE IDCupon = @IDCupon;

        INSERT INTO dbo.Pedidos
            (IDUsuario, Subtotal, Descuento, CostoEnvio, Total, BaseImponible, Iva, IDCupon, CodigoCupon,
             IDMetodoEnvio, NombreEnvio, IDDireccion, DestinatarioEnvio, TelefonoEnvio, DepartamentoEnvio,
             MunicipioEnvio, DireccionEnvio, ReferenciaEnvio, IDReserva)
        SELECT  @IDUsuario, @Subtotal, @Descuento, @CostoEnvio, @Total, @Base, @Iva, @IDCupon, cu.Codigo,
                @IDMetodoEnvio, @NombreEnvio, d.IDDireccion, d.NombreDestinatario, d.Telefono, d.Departamento,
                d.Municipio, d.Direccion, d.Referencia, @IDReserva
        FROM    dbo.Direcciones d
        LEFT JOIN dbo.Cupones cu ON cu.IDCupon = @IDCupon
        WHERE   d.IDDireccion = @IDDireccion;

        SET @FilasPedido = @@ROWCOUNT;
        SET @IDPedido = SCOPE_IDENTITY();

        IF @FilasPedido = 0
            THROW 50114, N'La dirección de entrega ya no está disponible.', 1;

        INSERT INTO @Lineas (IDVariante, SKU, NombreProducto, Atributos, PrecioUnitario, Cantidad, Subtotal, Elegible)
        SELECT  d.IDVariante, v.SKU, p.Nombre,
                LEFT((SELECT STRING_AGG(CONCAT(a.Nombre, N': ', va.Valor), N', ') WITHIN GROUP (ORDER BY a.Nombre)
                      FROM dbo.VarianteAtributos va
                      JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
                      WHERE va.IDVariante = v.IDVariante), 250),
                v.Precio, d.Cantidad,
                CAST(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio AS DECIMAL(18,2)),
                CAST(CASE WHEN @CategoriaCupon IS NULL OR p.IDCategoria = @CategoriaCupon THEN 1 ELSE 0 END AS BIT)
        FROM    dbo.CarritosDetalle d
        JOIN    dbo.Variantes v ON v.IDVariante = d.IDVariante
        JOIN    dbo.Productos p ON p.IDProducto = v.IDProducto
        WHERE   d.IDCarrito = @IDCarrito;

        IF @Descuento > 0
        BEGIN
            SELECT @SubElegible = SUM(Subtotal) FROM @Lineas WHERE Elegible = 1;

            UPDATE @Lineas
            SET    DescuentoLinea = CAST(ROUND(@Descuento * Subtotal / @SubElegible, 2) AS DECIMAL(18,2))
            WHERE  Elegible = 1;

            SELECT @Residuo = @Descuento - SUM(DescuentoLinea) FROM @Lineas;

            IF @Residuo <> 0
                UPDATE l
                SET    l.DescuentoLinea = l.DescuentoLinea + @Residuo
                FROM   @Lineas l
                WHERE  l.IDVariante = (SELECT TOP (1) IDVariante FROM @Lineas
                                       WHERE Elegible = 1 ORDER BY Subtotal DESC, IDVariante);
        END;

        INSERT INTO dbo.DetallePedidos
            (IDPedido, IDVariante, SKU, NombreProducto, Atributos, PrecioUnitario, Cantidad, Subtotal, DescuentoLinea)
        SELECT  @IDPedido, IDVariante, SKU, NombreProducto, Atributos, PrecioUnitario, Cantidad, Subtotal, DescuentoLinea
        FROM    @Lineas;

        EXEC Interno.SP_Inventario_ConsumirReserva @IDReserva = @IDReserva, @IDPedido = @IDPedido, @IDUsuario = @IDUsuario;

        IF @IDCupon IS NOT NULL
            EXEC Interno.SP_Cupones_RegistrarUso
                @IDCupon = @IDCupon, @IDUsuario = @IDUsuario, @IDPedido = @IDPedido, @MontoDescuento = @Descuento;

        UPDATE dbo.Carritos
        SET    Estado = N'CONVERTIDO', FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCarrito = @IDCarrito;

        INSERT INTO dbo.HistorialEstadosPedido (IDPedido, EstadoAnterior, EstadoNuevo, IDUsuario, Comentario)
        VALUES (@IDPedido, NULL, N'PAGADO', @IDUsuario, N'Pedido creado con pago aprobado');

        UPDATE dbo.Pagos
        SET    Estado = N'APROBADO', IDPedido = @IDPedido, ReferenciaPasarela = @ReferenciaPasarela,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDPago = @IDPago;

        SET @ValorNuevo = (
            SELECT @IDPedido AS IDPedido, @IDUsuario AS IDUsuario, N'PAGADO' AS Estado,
                   @Total AS Total, @IDCupon AS IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuario, @Modulo = N'Pedidos', @Entidad = N'Pedido',
            @IDEntidad = @IDPedido, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT  @IDPago AS IDPago, N'APROBADO' AS Estado, CAST(1 AS BIT) AS Nuevo, @IDPedido AS IDPedido,
                (SELECT NumeroPedido FROM dbo.Pedidos WHERE IDPedido = @IDPedido) AS NumeroPedido,
                @Total AS Total, CAST(NULL AS NVARCHAR(255)) AS Motivo;
    END TRY
    BEGIN CATCH
        DECLARE @NumError INT = ERROR_NUMBER(), @MsgError NVARCHAR(2000) = ERROR_MESSAGE();

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        IF @NumError IN (50070, 50095, 50114)
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION;

                UPDATE dbo.Pagos
                SET    Estado = N'ANULADO', Motivo = LEFT(@MsgError, 255),
                       ReferenciaPasarela = ISNULL(@ReferenciaPasarela, ReferenciaPasarela),
                       FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia AND Estado = N'INICIADO';

                SELECT @IDReserva = IDReserva
                FROM   dbo.Pagos
                WHERE  IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia;

                IF @IDReserva IS NOT NULL
                    EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDReserva, @NuevoEstado = N'LIBERADA';

                COMMIT TRANSACTION;

                SELECT  IDPago, N'ANULADO' AS Estado, CAST(1 AS BIT) AS Nuevo, CAST(NULL AS INT) AS IDPedido,
                        CAST(NULL AS NVARCHAR(20)) AS NumeroPedido, Monto AS Total, Motivo
                FROM    dbo.Pagos
                WHERE   IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia;
                RETURN;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                THROW;
            END CATCH;
        END;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Checkout_RechazarPago
    @IDUsuario         INT,
    @ClaveIdempotencia NVARCHAR(64),
    @Motivo            NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @ClaveIdempotencia = LTRIM(RTRIM(@ClaveIdempotencia));
    SET @Motivo = NULLIF(LTRIM(RTRIM(@Motivo)), N'');
    IF @ClaveIdempotencia IS NULL OR LEN(@ClaveIdempotencia) < 8 OR LEN(@ClaveIdempotencia) > 64
       OR @ClaveIdempotencia COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Za-z0-9_-]%'
        THROW 50053, N'La clave de idempotencia no es válida.', 1;

    DECLARE @IDPago INT, @EstadoPago NVARCHAR(12), @IDReserva INT, @IDPedido INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT  @IDPago = IDPago, @EstadoPago = Estado, @IDReserva = IDReserva, @IDPedido = IDPedido
        FROM    dbo.Pagos WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDUsuario = @IDUsuario AND ClaveIdempotencia = @ClaveIdempotencia;

        IF @IDPago IS NULL
            THROW 50113, N'El pago no existe.', 1;

        IF @EstadoPago = N'INICIADO'
        BEGIN
            UPDATE dbo.Pagos
            SET    Estado = N'RECHAZADO',
                   Motivo = ISNULL(LEFT(@Motivo, 255), N'Pago rechazado por la pasarela.'),
                   FechaActualizacion = SYSUTCDATETIME()
            WHERE  IDPago = @IDPago;

            IF @IDReserva IS NOT NULL
                EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDReserva, @NuevoEstado = N'LIBERADA';

            SET @EstadoPago = N'RECHAZADO';
        END;

        COMMIT TRANSACTION;

        SELECT @IDPago AS IDPago, @EstadoPago AS Estado, @IDPedido AS IDPedido;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
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
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'020_Checkout_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'020_Checkout_Procedimientos.sql');
GO