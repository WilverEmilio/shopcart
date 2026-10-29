/* =============================================================================
   011_Inventario_Procedimientos.sql
   Módulo 3 - Inventario: movimientos, reservas, kardex y conciliación.
   Reejecutable (CREATE OR ALTER).

   Códigos de error personalizados (THROW):
     50060 El kardex es inmutable                                   -> 500
     50061 La existencia resultaría negativa                        -> 409
     50062 Reservas inconsistentes (resultaría negativa)            -> 500
     50063 El movimiento dejaría la existencia por debajo de lo
           reservado                                                -> 409
     50064 Movimiento ya registrado para esa referencia             -> 409
     50066 Cantidad inválida (cero, negativa o signo incorrecto)    -> 400
     50067 Existencias insuficientes para reservar                  -> 409
     50068 Producto no disponible para la venta                     -> 409
     50069 Reserva no encontrada                                    -> 404
     50070 Reserva vencida o ya no activa                           -> 409
     50071 El motivo es obligatorio                                 -> 400
     50072 Ya hay un proceso de pago en curso para el usuario       -> 409
   Reutiliza 50057 (variante no encontrada) y 50053 (datos inválidos).
   Un error 1205 (deadlock) debe reintentarse en el backend (hasta 3 veces).

   Esquema Interno (no expuesto a la aplicación):
     Interno.SP_Inventario_AplicarMovimiento  único punto que cambia ExistenciaFisica
     Interno.SP_Inventario_CerrarReserva      libera/vence una reserva
     Interno.SP_Inventario_ConsumirReserva    convierte la reserva en SALIDA (checkout)
   Los módulos de pedidos y devoluciones usarán AplicarMovimiento con los tipos
   SALIDA, CANCELACION y DEVOLUCION y TipoReferencia = PEDIDO | DEVOLUCION.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Inventario_AplicarMovimiento
    @IDVariante         INT,
    @TipoMovimiento     NVARCHAR(20),
    @Cantidad           INT,
    @Motivo             NVARCHAR(255),
    @IDUsuario          INT,
    @TipoReferencia     NVARCHAR(20) = NULL,
    @IDReferencia       INT          = NULL,
    @LiberarReservada   BIT          = 0,
    @IDMovimiento       BIGINT       = NULL OUTPUT,
    @ExistenciaAnterior INT          = NULL OUTPUT,
    @ExistenciaNueva    INT          = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Motivo = LTRIM(RTRIM(@Motivo));
    IF @Cantidad IS NULL OR @Cantidad = 0
        THROW 50066, N'La cantidad no puede ser cero.', 1;
    IF @Motivo IS NULL OR @Motivo = N''
        THROW 50071, N'El motivo es obligatorio.', 1;
    IF NOT (   (@TipoMovimiento IN (N'ENTRADA', N'DEVOLUCION', N'CANCELACION') AND @Cantidad > 0)
            OR (@TipoMovimiento = N'SALIDA' AND @Cantidad < 0)
            OR  @TipoMovimiento = N'AJUSTE')
        THROW 50066, N'El signo de la cantidad no corresponde al tipo de movimiento.', 1;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Reservada INT, @NuevaReservada INT;

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        SELECT  @ExistenciaAnterior = ExistenciaFisica,
                @Reservada = ExistenciaReservada
        FROM    dbo.Variantes WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDVariante = @IDVariante;

        IF @ExistenciaAnterior IS NULL
            THROW 50057, N'La variante no existe.', 1;

        SET @ExistenciaNueva = @ExistenciaAnterior + @Cantidad;
        SET @NuevaReservada  = @Reservada - CASE WHEN @LiberarReservada = 1 THEN ABS(@Cantidad) ELSE 0 END;

        IF @ExistenciaNueva < 0
            THROW 50061, N'La existencia no puede quedar en negativo.', 1;
        IF @NuevaReservada < 0
            THROW 50062, N'La existencia reservada resultaría negativa.', 1;
        IF @ExistenciaNueva < @NuevaReservada
            THROW 50063, N'El movimiento dejaría la existencia por debajo de las unidades reservadas.', 1;

        INSERT INTO dbo.MovimientosInventario
            (IDVariante, TipoMovimiento, Cantidad, ExistenciaResultante, Motivo, TipoReferencia, IDReferencia, IDUsuario)
        VALUES
            (@IDVariante, @TipoMovimiento, @Cantidad, @ExistenciaNueva, @Motivo, @TipoReferencia, @IDReferencia, @IDUsuario);

        SET @IDMovimiento = SCOPE_IDENTITY();

        UPDATE dbo.Variantes
        SET    ExistenciaFisica = @ExistenciaNueva,
               ExistenciaReservada = @NuevaReservada,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDVariante = @IDVariante;

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627) AND ERROR_MESSAGE() LIKE N'%UX_MovimientosInventario_Referencia%'
            THROW 50064, N'Ya existe ese movimiento para la referencia indicada.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Inventario_CerrarReserva
    @IDReserva   INT,
    @NuevoEstado NVARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @NuevoEstado NOT IN (N'LIBERADA', N'VENCIDA')
        THROW 50053, N'El estado de cierre debe ser LIBERADA o VENCIDA.', 1;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Estado NVARCHAR(12);

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        SELECT @Estado = Estado
        FROM   dbo.Reservas WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDReserva = @IDReserva;

        IF @Estado IS NULL
            THROW 50069, N'La reserva no existe.', 1;

        IF @Estado = N'ACTIVA'
        BEGIN
            UPDATE v
            SET    v.ExistenciaReservada = v.ExistenciaReservada - d.Cantidad
            FROM   dbo.Variantes v
            JOIN   dbo.ReservasDetalle d ON d.IDVariante = v.IDVariante
            WHERE  d.IDReserva = @IDReserva;

            UPDATE dbo.Reservas
            SET    Estado = @NuevoEstado, FechaCierre = SYSUTCDATETIME()
            WHERE  IDReserva = @IDReserva;
        END;

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Confirma el pago: la reserva se convierte en SALIDAS del kardex (una por
   variante, en orden ascendente de IDVariante para reducir interbloqueos) y
   descuenta lo reservado. Debe llamarse dentro de la transacción de creación
   del pedido, con el pedido ya insertado. */
CREATE OR ALTER PROCEDURE Interno.SP_Inventario_ConsumirReserva
    @IDReserva INT,
    @IDPedido  INT,
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Estado NVARCHAR(12), @Vencimiento DATETIME2(0), @Dueno INT,
            @IDVariante INT = 0, @Cantidad INT, @CantidadSalida INT, @Motivo NVARCHAR(255);

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        SELECT  @Estado = Estado, @Vencimiento = FechaVencimiento, @Dueno = IDUsuario
        FROM    dbo.Reservas WITH (UPDLOCK, HOLDLOCK)
        WHERE   IDReserva = @IDReserva;

        IF @Estado IS NULL OR @Dueno <> @IDUsuario
            THROW 50069, N'La reserva no existe.', 1;
        IF @Estado <> N'ACTIVA' OR @Vencimiento <= SYSUTCDATETIME()
            THROW 50070, N'La reserva venció o ya no está activa; vuelva a iniciar el pago.', 1;

        SET @Motivo = CONCAT(N'Venta - pedido ', @IDPedido);

        WHILE 1 = 1
        BEGIN
            SELECT TOP (1) @IDVariante = IDVariante, @Cantidad = Cantidad
            FROM   dbo.ReservasDetalle
            WHERE  IDReserva = @IDReserva AND IDVariante > @IDVariante
            ORDER BY IDVariante;

            IF @@ROWCOUNT = 0 BREAK;

            SET @CantidadSalida = -@Cantidad;

            EXEC Interno.SP_Inventario_AplicarMovimiento
                @IDVariante = @IDVariante, @TipoMovimiento = N'SALIDA', @Cantidad = @CantidadSalida,
                @Motivo = @Motivo, @IDUsuario = @IDUsuario,
                @TipoReferencia = N'PEDIDO', @IDReferencia = @IDPedido, @LiberarReservada = 1;
        END;

        UPDATE dbo.Reservas
        SET    Estado = N'CONSUMIDA', FechaCierre = SYSUTCDATETIME()
        WHERE  IDReserva = @IDReserva;

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* ===========================================================================
   MOVIMIENTOS MANUALES (Operador / Administrador)
   =========================================================================== */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_RegistrarEntrada
    @IDUsuarioActor INT,
    @IDVariante     INT,
    @Cantidad       INT,
    @Motivo         NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'INVENTARIO_GESTIONAR';

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 50066, N'La cantidad de una entrada debe ser mayor a cero.', 1;

    DECLARE @IDMovimiento BIGINT, @Anterior INT, @Nueva INT,
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Inventario_AplicarMovimiento
            @IDVariante = @IDVariante, @TipoMovimiento = N'ENTRADA', @Cantidad = @Cantidad,
            @Motivo = @Motivo, @IDUsuario = @IDUsuarioActor,
            @IDMovimiento = @IDMovimiento OUTPUT, @ExistenciaAnterior = @Anterior OUTPUT, @ExistenciaNueva = @Nueva OUTPUT;

        SET @ValorAnterior = (SELECT @Anterior AS ExistenciaFisica FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo = (
            SELECT @Nueva AS ExistenciaFisica, @IDMovimiento AS IDMovimiento,
                   N'ENTRADA' AS TipoMovimiento, @Cantidad AS Cantidad, LTRIM(RTRIM(@Motivo)) AS Motivo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Inventario', @Entidad = N'Variante',
            @IDEntidad = @IDVariante, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDMovimiento AS IDMovimiento, @Anterior AS ExistenciaAnterior, @Nueva AS ExistenciaNueva;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* @Cantidad con signo: positiva suma, negativa resta. Exige motivo y no puede
   dejar la existencia en negativo ni por debajo de lo reservado. */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_RegistrarAjuste
    @IDUsuarioActor INT,
    @IDVariante     INT,
    @Cantidad       INT,
    @Motivo         NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'INVENTARIO_GESTIONAR';

    IF @Cantidad IS NULL OR @Cantidad = 0
        THROW 50066, N'El ajuste no puede ser cero.', 1;

    DECLARE @IDMovimiento BIGINT, @Anterior INT, @Nueva INT,
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Inventario_AplicarMovimiento
            @IDVariante = @IDVariante, @TipoMovimiento = N'AJUSTE', @Cantidad = @Cantidad,
            @Motivo = @Motivo, @IDUsuario = @IDUsuarioActor,
            @IDMovimiento = @IDMovimiento OUTPUT, @ExistenciaAnterior = @Anterior OUTPUT, @ExistenciaNueva = @Nueva OUTPUT;

        SET @ValorAnterior = (SELECT @Anterior AS ExistenciaFisica FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo = (
            SELECT @Nueva AS ExistenciaFisica, @IDMovimiento AS IDMovimiento,
                   N'AJUSTE' AS TipoMovimiento, @Cantidad AS Cantidad, LTRIM(RTRIM(@Motivo)) AS Motivo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Inventario', @Entidad = N'Variante',
            @IDEntidad = @IDVariante, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDMovimiento AS IDMovimiento, @Anterior AS ExistenciaAnterior, @Nueva AS ExistenciaNueva;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* ===========================================================================
   RESERVAS
   =========================================================================== */

/* Reserva 15 minutos las unidades de cada variante (inicio del pago).
   @Items: [{"idVariante":1,"cantidad":2}]
   - Atómico: reserva todo o nada. Si dos clientes piden la última unidad,
     solo uno la obtiene; el otro recibe 50067 con un mensaje claro.
   - Libera antes la reserva activa del propio usuario y las vencidas que
     afecten a estas variantes, así un job caído no bloquea el stock. */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_ReservarExistencia
    @IDUsuarioActor INT,
    @Items          NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'COMPRAR';

    IF @Items IS NULL OR ISJSON(@Items) <> 1
        THROW 50053, N'La lista de productos a reservar no es un JSON válido.', 1;

    DECLARE @MinutosVigencia INT = 15;
    DECLARE @IDReserva INT, @Vencimiento DATETIME2(0), @Falla NVARCHAR(400),
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

        /* 1) Libera la reserva activa previa del mismo usuario (la serializa ante doble clic) */
        SELECT @IDPrevia = IDReserva
        FROM   dbo.Reservas WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDUsuario = @IDUsuarioActor AND Estado = N'ACTIVA';

        IF @IDPrevia IS NOT NULL
            EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDPrevia, @NuevoEstado = N'LIBERADA';

        /* 2) Vence las reservas caducadas que afecten a estas variantes */
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

        /* 3) Validaciones con bloqueo, para dar un mensaje claro */
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

        /* 4) Reserva atómica: la condición del UPDATE es la barrera final contra la sobreventa */
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

/* El dueño de la reserva (o quien gestiona inventario) la libera antes de que venza.
   Idempotente. Si no es suyo, se responde como "no existe" para no filtrar datos. */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_LiberarReserva
    @IDUsuarioActor INT,
    @IDReserva      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Dueno INT;

    SELECT @Dueno = IDUsuario FROM dbo.Reservas WHERE IDReserva = @IDReserva;

    IF @Dueno IS NULL
        THROW 50069, N'La reserva no existe.', 1;

    IF @Dueno <> @IDUsuarioActor
       AND NOT EXISTS (
            SELECT 1
            FROM dbo.Usuarios u
            JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
            JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
            WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1 AND p.Codigo = N'INVENTARIO_GESTIONAR')
        THROW 50069, N'La reserva no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDReserva, @NuevoEstado = N'LIBERADA';

        COMMIT TRANSACTION;

        SELECT IDReserva, Estado FROM dbo.Reservas WHERE IDReserva = @IDReserva;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Lo invoca el job del backend cada minuto. Cada reserva se cierra en su propia
   transacción; si una falla (p. ej. deadlock) se reintenta en la siguiente corrida. */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_LiberarReservasVencidas
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDReserva INT = 0, @Liberadas INT = 0;

    WHILE 1 = 1
    BEGIN
        SELECT TOP (1) @IDReserva = IDReserva
        FROM   dbo.Reservas
        WHERE  Estado = N'ACTIVA'
          AND  FechaVencimiento <= SYSUTCDATETIME()
          AND  IDReserva > @IDReserva
        ORDER BY IDReserva;

        IF @@ROWCOUNT = 0 BREAK;

        BEGIN TRY
            EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDReserva, @NuevoEstado = N'VENCIDA';
            SET @Liberadas = @Liberadas + 1;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        END CATCH;
    END;

    SELECT @Liberadas AS ReservasLiberadas;
END;
GO

/* ===========================================================================
   CONSULTAS (Operador / Administrador)
   =========================================================================== */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_ListarKardex
    @IDUsuarioActor INT,
    @IDVariante     INT           = NULL,
    @TipoMovimiento NVARCHAR(20)  = NULL,
    @FechaDesde     DATETIME2(0)  = NULL,
    @FechaHasta     DATETIME2(0)  = NULL,
    @Texto          NVARCHAR(100) = NULL,
    @Pagina         INT           = 1,
    @TamanoPagina   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'INVENTARIO_GESTIONAR';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    DECLARE @Patron NVARCHAR(102) =
        CASE WHEN @Texto IS NULL OR LTRIM(RTRIM(@Texto)) = N'' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Texto)) + N'%' END;

    SELECT  m.IDMovimiento, m.Fecha, m.TipoMovimiento, m.Cantidad, m.ExistenciaResultante,
            m.Motivo, m.TipoReferencia, m.IDReferencia,
            v.IDVariante, v.SKU, p.Nombre AS Producto,
            u.IDUsuario, u.Correo AS CorreoUsuario,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.MovimientosInventario m
    JOIN    dbo.Variantes v ON v.IDVariante = m.IDVariante
    JOIN    dbo.Productos p ON p.IDProducto = v.IDProducto
    JOIN    dbo.Usuarios u  ON u.IDUsuario = m.IDUsuario
    WHERE   (@IDVariante IS NULL OR m.IDVariante = @IDVariante)
        AND (@TipoMovimiento IS NULL OR m.TipoMovimiento = @TipoMovimiento)
        AND (@FechaDesde IS NULL OR m.Fecha >= @FechaDesde)
        AND (@FechaHasta IS NULL OR m.Fecha <= @FechaHasta)
        AND (@Patron IS NULL OR v.SKU LIKE @Patron OR p.Nombre LIKE @Patron)
    ORDER BY m.Fecha DESC, m.IDMovimiento DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Inventario_ListarExistencias
    @IDUsuarioActor        INT,
    @Texto                 NVARCHAR(100) = NULL,
    @IDCategoria           INT           = NULL,
    @SoloSinDisponibilidad BIT           = 0,
    @Activo                BIT           = NULL,
    @OrdenarPor            NVARCHAR(20)  = N'Producto',   -- SKU | Producto | Disponible
    @Direccion             NVARCHAR(4)   = N'ASC',        -- ASC | DESC
    @Pagina                INT           = 1,
    @TamanoPagina          INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'INVENTARIO_GESTIONAR';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;
    SET @SoloSinDisponibilidad = ISNULL(@SoloSinDisponibilidad, 0);

    DECLARE @Patron NVARCHAR(102) =
        CASE WHEN @Texto IS NULL OR LTRIM(RTRIM(@Texto)) = N'' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Texto)) + N'%' END;

    SELECT  v.IDVariante, v.SKU, p.IDProducto, p.Nombre AS Producto,
            c.IDCategoria, c.Nombre AS Categoria,
            v.ExistenciaFisica, v.ExistenciaReservada, v.ExistenciaDisponible, v.Activo,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.Variantes v
    JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
    JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
    WHERE   (@IDCategoria IS NULL OR p.IDCategoria = @IDCategoria)
        AND (@Activo IS NULL OR v.Activo = @Activo)
        AND (@SoloSinDisponibilidad = 0 OR v.ExistenciaDisponible <= 0)
        AND (@Patron IS NULL OR v.SKU LIKE @Patron OR p.Nombre LIKE @Patron)
    ORDER BY
        CASE WHEN @OrdenarPor = N'SKU'        AND @Direccion = N'ASC'  THEN v.SKU                  END ASC,
        CASE WHEN @OrdenarPor = N'SKU'        AND @Direccion = N'DESC' THEN v.SKU                  END DESC,
        CASE WHEN @OrdenarPor = N'Producto'   AND @Direccion = N'ASC'  THEN p.Nombre               END ASC,
        CASE WHEN @OrdenarPor = N'Producto'   AND @Direccion = N'DESC' THEN p.Nombre               END DESC,
        CASE WHEN @OrdenarPor = N'Disponible' AND @Direccion = N'ASC'  THEN v.ExistenciaDisponible END ASC,
        CASE WHEN @OrdenarPor = N'Disponible' AND @Direccion = N'DESC' THEN v.ExistenciaDisponible END DESC,
        v.IDVariante
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

/* Verifica que contadores y fuentes de verdad coincidan (las diferencias deben ser 0). */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_ObtenerConciliacion
    @IDUsuarioActor  INT,
    @SoloDiferencias BIT = 1,
    @Pagina          INT = 1,
    @TamanoPagina    INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'INVENTARIO_GESTIONAR';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 50;
    IF @TamanoPagina > 200 SET @TamanoPagina = 200;
    SET @SoloDiferencias = ISNULL(@SoloDiferencias, 1);

    SELECT  c.IDVariante, c.SKU,
            c.ExistenciaFisica, c.SumaKardex, c.DiferenciaFisica,
            c.ExistenciaReservada, c.SumaReservasActivas, c.DiferenciaReservada,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.VW_Inventario_Conciliacion c
    WHERE   (@SoloDiferencias = 0 OR c.DiferenciaFisica <> 0 OR c.DiferenciaReservada <> 0)
    ORDER BY c.IDVariante
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'011_Inventario_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'011_Inventario_Procedimientos.sql');
GO