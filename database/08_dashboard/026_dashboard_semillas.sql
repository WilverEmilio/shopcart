/* =============================================================================
   025_Reportes_Semilla.sql
   1) Configuración del sistema y permiso CONFIGURACION_GESTIONAR (Administrador).
   2) Datos de demostración con VOLUMEN para validar que los listados y reportes
      responden en menos de 1 segundo:
        - 60 clientes de demostración (cliente01..cliente60@demo.shopcart.local),
          sin contraseña válida: no pueden iniciar sesión.
        - 3,000 pedidos repartidos en los últimos 120 días, en todos los estados,
          con su historial de estados, devoluciones y movimientos de kardex.
        - 18 carritos con distinta inactividad (para "carritos abandonados").
      Los pedidos de demostración se insertan directamente (sin pasar por el
      checkout), con precios congelados y existencias coherentes: el kardex, las
      existencias y la conciliación cuadran.
   Requiere los scripts 012 (stock inicial) y 019 (métodos de envío).
   Reejecutable: no carga nada si ya existen pedidos.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.Configuracion (Clave, Valor, Descripcion)
SELECT v.Clave, v.Valor, v.Descripcion
FROM (VALUES
    (N'OffsetHorasLocal',    N'-6',  N'Diferencia en horas entre la hora local (Guatemala) y UTC; se usa para agrupar los reportes por día'),
    (N'AbandonoCarritoHoras', N'24', N'Horas sin actividad para considerar abandonado un carrito con productos')
) AS v (Clave, Valor, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Configuracion c WHERE c.Clave = v.Clave);
GO

INSERT INTO dbo.Permisos (Codigo, Descripcion)
SELECT N'CONFIGURACION_GESTIONAR', N'Consultar y modificar la configuración del sistema'
WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Codigo = N'CONFIGURACION_GESTIONAR');
GO

INSERT INTO dbo.RolesPermisos (IDRol, IDPermiso)
SELECT r.IDRol, p.IDPermiso
FROM   dbo.Roles r
JOIN   dbo.Permisos p ON p.Codigo = N'CONFIGURACION_GESTIONAR'
WHERE  r.Nombre = N'Administrador'
  AND  NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos rp WHERE rp.IDRol = r.IDRol AND rp.IDPermiso = p.IDPermiso);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Pedidos)
   AND EXISTS (SELECT 1 FROM dbo.MovimientosInventario)
BEGIN
    DECLARE @Ahora DATETIME2(0) = SYSUTCDATETIME();
    DECLARE @DiasHistorial INT = 120, @NumPedidos INT = 3000, @NumClientes INT = 60;
    DECLARE @Minutos INT = @DiasHistorial * 1440;
    DECLARE @InicioCarga DATETIME2(0) = DATEADD(DAY, -(@DiasHistorial + 6), @Ahora);
    DECLARE @InicioRepo  DATETIME2(0) = DATEADD(DAY, -(@DiasHistorial + 3), @Ahora);
    DECLARE @IDSistema INT = (SELECT IDUsuario FROM dbo.Usuarios WHERE Correo = N'sistema@shopcart.local');
    DECLARE @IDRolCliente INT = (SELECT IDRol FROM dbo.Roles WHERE Nombre = N'Cliente');
    DECLARE @P INT, @TotClientes INT, @TotEnvios INT;

    IF @IDSistema IS NULL
        THROW 50099, N'Falta el usuario de sistema: ejecute antes el script 012.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.MovimientosInventario
                   WHERE Motivo = N'Carga inicial de inventario' AND Fecha > @InicioCarga)
        BEGIN
            DISABLE TRIGGER dbo.TR_MovimientosInventario_Inmutable ON dbo.MovimientosInventario;

            UPDATE dbo.MovimientosInventario
            SET    Fecha = @InicioCarga
            WHERE  Motivo = N'Carga inicial de inventario' AND Fecha > @InicioCarga;

            ENABLE TRIGGER dbo.TR_MovimientosInventario_Inmutable ON dbo.MovimientosInventario;
        END;

        ;WITH Nombres (Id, Nombre) AS (
            SELECT Id, Nombre FROM (VALUES (0, N'María'), (1, N'José'), (2, N'Ana'), (3, N'Luis'), (4, N'Carmen'),
                                           (5, N'Carlos'), (6, N'Sofía'), (7, N'Diego'), (8, N'Lucía'), (9, N'Miguel')) x (Id, Nombre)
        ),
        Apellidos (Id, Apellido) AS (
            SELECT Id, Apellido FROM (VALUES (0, N'López'), (1, N'García'), (2, N'Pérez'), (3, N'Morales'),
                                             (4, N'Hernández'), (5, N'Ajú')) x (Id, Apellido)
        ),
        N AS (
            SELECT TOP (@NumClientes) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects
        )
        INSERT INTO dbo.Usuarios (IDRol, Correo, PasswordHash, Nombres, Apellidos, Telefono)
        SELECT  @IDRolCliente,
                CONCAT(N'cliente', RIGHT(CONCAT(N'00', N.n), 2), N'@demo.shopcart.local'),
                N'!SIN-ACCESO',
                nm.Nombre, ap.Apellido,
                CONCAT(N'5555-', RIGHT(CONCAT(N'0000', N.n), 4))
        FROM    N
        JOIN    Nombres nm   ON nm.Id = (N.n - 1) % 10
        JOIN    Apellidos ap ON ap.Id = ((N.n - 1) / 10) % 6
        WHERE   NOT EXISTS (SELECT 1 FROM dbo.Usuarios u
                            WHERE u.Correo = CONCAT(N'cliente', RIGHT(CONCAT(N'00', N.n), 2), N'@demo.shopcart.local'));

        SELECT  ROW_NUMBER() OVER (ORDER BY IDUsuario) AS Ord, IDUsuario, Nombres, Apellidos
        INTO    #Clientes
        FROM    dbo.Usuarios
        WHERE   Correo LIKE N'%@demo.shopcart.local';

        SELECT  ROW_NUMBER() OVER (ORDER BY IDMetodoEnvio) AS Ord, IDMetodoEnvio, Nombre, Costo
        INTO    #Envios
        FROM    dbo.MetodosEnvio
        WHERE   Activo = 1;

        SELECT @TotClientes = COUNT(*) FROM #Clientes;
        SELECT @TotEnvios = COUNT(*) FROM #Envios;

        IF @TotClientes = 0 OR @TotEnvios = 0
            THROW 50099, N'Faltan clientes de demostración o métodos de envío (ejecute el script 019).', 1;

        SELECT  v.IDVariante, CASE WHEN v.IDVariante % 5 = 0 THEN 4 ELSE 1 END AS Peso
        INTO    #Elegibles
        FROM    dbo.Variantes v
        WHERE   v.Activo = 1 AND v.ExistenciaFisica >= 20;

        SELECT  ROW_NUMBER() OVER (ORDER BY t.n, e.IDVariante) AS Pos, e.IDVariante
        INTO    #Pool
        FROM    #Elegibles e
        JOIN    (VALUES (1), (2), (3), (4)) t (n) ON t.n <= e.Peso;

        SELECT @P = COUNT(*) FROM #Pool;

        IF @P < 100
            THROW 50099, N'No hay suficientes variantes con existencia: ejecute antes los scripts 008 y 012.', 1;

        INSERT INTO dbo.MovimientosInventario
            (IDVariante, TipoMovimiento, Cantidad, ExistenciaResultante, Motivo, IDUsuario, Fecha)
        SELECT  e.IDVariante, N'ENTRADA', 200, v.ExistenciaFisica + 200,
                N'Reposición de temporada (datos de demostración)', @IDSistema, @InicioRepo
        FROM    #Elegibles e
        JOIN    dbo.Variantes v ON v.IDVariante = e.IDVariante
        ORDER BY e.IDVariante;

        UPDATE v
        SET    v.ExistenciaFisica = v.ExistenciaFisica + 200
        FROM   dbo.Variantes v
        JOIN   #Elegibles e ON e.IDVariante = v.IDVariante;

        SELECT IDVariante, ExistenciaFisica AS Apertura INTO #Apertura FROM dbo.Variantes;

        SELECT  n.n, c.IDUsuario, c.Nombres, c.Apellidos,
                mm.MinutosAtras,
                DATEADD(MINUTE, -mm.MinutosAtras, @Ahora) AS Fecha,
                1 + (n.n % 4) AS NLineas,
                en.IDMetodoEnvio, en.Nombre AS NombreEnvio, en.Costo AS CostoEnvio,
                CASE
                    WHEN mm.MinutosAtras < 1440 THEN CASE WHEN n.n % 2 = 0 THEN N'PAGADO' ELSE N'EN_PREPARACION' END
                    WHEN mm.MinutosAtras < 4320 THEN CASE WHEN n.n % 2 = 0 THEN N'EN_PREPARACION' ELSE N'DESPACHADO' END
                    WHEN mm.MinutosAtras < 8640 THEN CASE WHEN n.n % 3 = 0 THEN N'DESPACHADO' ELSE N'ENTREGADO' END
                    WHEN n.n % 20 = 0 THEN N'CANCELADO'
                    WHEN n.n % 25 = 1 AND n.n % 4 >= 1 THEN N'DEVUELTO_PARCIAL'
                    WHEN n.n % 40 = 2 THEN N'DEVUELTO'
                    ELSE N'ENTREGADO'
                END AS Estado
        INTO    #Ped
        FROM   (SELECT TOP (@NumPedidos) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
                FROM sys.all_objects a CROSS JOIN sys.all_objects b) n
        CROSS APPLY (SELECT 30 + ((n.n * 7919) % (@Minutos - 30)) AS MinutosAtras) mm
        JOIN    #Clientes c  ON c.Ord  = ((n.n * 7) % @TotClientes) + 1
        JOIN    #Envios en   ON en.Ord = (n.n % @TotEnvios) + 1;

        SELECT  p.n, k.k, ROW_NUMBER() OVER (ORDER BY p.n, k.k) AS Seq
        INTO    #Lin
        FROM    #Ped p
        JOIN    (VALUES (1), (2), (3), (4)) k (k) ON k.k <= p.NLineas;

        SELECT  l.n, l.k, pool.IDVariante,
                1 + ((l.n + l.k) % 2) AS Cantidad,
                v.Precio, v.SKU, pr.Nombre
        INTO    #Lineas
        FROM    #Lin l
        JOIN    #Pool pool      ON pool.Pos = ((l.Seq - 1) % @P) + 1
        JOIN    dbo.Variantes v ON v.IDVariante = pool.IDVariante
        JOIN    dbo.Productos pr ON pr.IDProducto = v.IDProducto;

        SELECT  n, SUM(CAST(Cantidad AS DECIMAL(18,2)) * Precio) AS Subtotal
        INTO    #Tot
        FROM    #Lineas
        GROUP BY n;

        INSERT INTO dbo.Pedidos
            (IDUsuario, Estado, Subtotal, Descuento, CostoEnvio, Total, BaseImponible, Iva,
             IDMetodoEnvio, NombreEnvio, DestinatarioEnvio, TelefonoEnvio, DepartamentoEnvio, MunicipioEnvio,
             DireccionEnvio, FechaCreacion, FechaActualizacion)
        SELECT  p.IDUsuario, p.Estado, t.Subtotal, 0, p.CostoEnvio,
                t.Subtotal + p.CostoEnvio,
                CAST(ROUND((t.Subtotal + p.CostoEnvio) / 1.12, 2) AS DECIMAL(18,2)),
                (t.Subtotal + p.CostoEnvio) - CAST(ROUND((t.Subtotal + p.CostoEnvio) / 1.12, 2) AS DECIMAL(18,2)),
                p.IDMetodoEnvio, p.NombreEnvio, CONCAT(p.Nombres, N' ', p.Apellidos), N'5555-0000',
                N'Quetzaltenango', N'Quetzaltenango', N'3a. calle 5-10 zona 1',
                p.Fecha,
                CASE WHEN DATEADD(MINUTE, ult.Minutos, p.Fecha) > @Ahora THEN @Ahora
                     ELSE DATEADD(MINUTE, ult.Minutos, p.Fecha) END
        FROM    #Ped p
        JOIN    #Tot t ON t.n = p.n
        CROSS APPLY (SELECT CASE p.Estado
                                WHEN N'PAGADO' THEN 0 WHEN N'EN_PREPARACION' THEN 120 WHEN N'DESPACHADO' THEN 1440
                                WHEN N'ENTREGADO' THEN 4320 WHEN N'CANCELADO' THEN 180 ELSE 7200 END AS Minutos) ult
        ORDER BY p.n;

        SELECT ROW_NUMBER() OVER (ORDER BY IDPedido) AS n, IDPedido INTO #Mapa FROM dbo.Pedidos;

        INSERT INTO dbo.DetallePedidos
            (IDPedido, IDVariante, SKU, NombreProducto, Atributos, PrecioUnitario, Cantidad, Subtotal,
             DescuentoLinea, CantidadDevuelta)
        SELECT  m.IDPedido, l.IDVariante, l.SKU, l.Nombre,
                LEFT((SELECT STRING_AGG(CONCAT(a.Nombre, N': ', va.Valor), N', ') WITHIN GROUP (ORDER BY a.Nombre)
                      FROM dbo.VarianteAtributos va
                      JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
                      WHERE va.IDVariante = l.IDVariante), 250),
                l.Precio, l.Cantidad, CAST(l.Cantidad AS DECIMAL(18,2)) * l.Precio, 0,
                CASE WHEN p.Estado = N'DEVUELTO' THEN l.Cantidad
                     WHEN p.Estado = N'DEVUELTO_PARCIAL' AND l.k = 1 THEN 1
                     ELSE 0 END
        FROM    #Lineas l
        JOIN    #Mapa m ON m.n = l.n
        JOIN    #Ped p  ON p.n = l.n
        ORDER BY l.n, l.k;

        /* 5) Historial de estados */
        DECLARE @Pasos TABLE (EstadoFinal NVARCHAR(20), Orden INT, Estado NVARCHAR(20), Minutos INT);
        INSERT INTO @Pasos (EstadoFinal, Orden, Estado, Minutos) VALUES
            (N'PAGADO',           1, N'PAGADO',         0),
            (N'EN_PREPARACION',   1, N'PAGADO',         0), (N'EN_PREPARACION', 2, N'EN_PREPARACION', 120),
            (N'DESPACHADO',       1, N'PAGADO',         0), (N'DESPACHADO',     2, N'EN_PREPARACION', 120), (N'DESPACHADO', 3, N'DESPACHADO', 1440),
            (N'ENTREGADO',        1, N'PAGADO',         0), (N'ENTREGADO',      2, N'EN_PREPARACION', 120), (N'ENTREGADO',  3, N'DESPACHADO', 1440), (N'ENTREGADO', 4, N'ENTREGADO', 4320),
            (N'CANCELADO',        1, N'PAGADO',         0), (N'CANCELADO',      2, N'CANCELADO',      180),
            (N'DEVUELTO_PARCIAL', 1, N'PAGADO',         0), (N'DEVUELTO_PARCIAL', 2, N'EN_PREPARACION', 120), (N'DEVUELTO_PARCIAL', 3, N'DESPACHADO', 1440),
            (N'DEVUELTO_PARCIAL', 4, N'ENTREGADO',   4320), (N'DEVUELTO_PARCIAL', 5, N'DEVUELTO_PARCIAL', 7200),
            (N'DEVUELTO',         1, N'PAGADO',         0), (N'DEVUELTO',       2, N'EN_PREPARACION', 120), (N'DEVUELTO',   3, N'DESPACHADO', 1440),
            (N'DEVUELTO',         4, N'ENTREGADO',   4320), (N'DEVUELTO',       5, N'DEVUELTO',      7200);

        INSERT INTO dbo.HistorialEstadosPedido (IDPedido, EstadoAnterior, EstadoNuevo, IDUsuario, Fecha, Comentario)
        SELECT  m.IDPedido,
                LAG(s.Estado) OVER (PARTITION BY m.IDPedido ORDER BY s.Orden),
                s.Estado,
                @IDSistema,
                CASE WHEN DATEADD(MINUTE, s.Minutos, p.Fecha) > @Ahora THEN @Ahora
                     ELSE DATEADD(MINUTE, s.Minutos, p.Fecha) END,
                CASE WHEN s.Orden = 1 THEN N'Pedido creado con pago aprobado' ELSE N'Datos de demostración' END
        FROM    #Ped p
        JOIN    #Mapa m  ON m.n = p.n
        JOIN    @Pasos s ON s.EstadoFinal = p.Estado
        ORDER BY m.IDPedido, s.Orden;

        SELECT  ROW_NUMBER() OVER (ORDER BY p.n) AS Rk, p.n, m.IDPedido,
                DATEADD(MINUTE, 7200, p.Fecha) AS Fecha,
                SUM(CASE WHEN p.Estado = N'DEVUELTO' THEN CAST(l.Cantidad AS DECIMAL(18,2)) * l.Precio
                         WHEN l.k = 1 THEN l.Precio ELSE 0 END) AS Monto
        INTO    #Dev
        FROM    #Ped p
        JOIN    #Mapa m   ON m.n = p.n
        JOIN    #Lineas l ON l.n = p.n
        WHERE   p.Estado IN (N'DEVUELTO', N'DEVUELTO_PARCIAL')
        GROUP BY p.n, m.IDPedido, p.Fecha, p.Estado;

        INSERT INTO dbo.Devoluciones (IDPedido, IDUsuario, Motivo, MontoReembolso, Fecha)
        SELECT  IDPedido, @IDSistema, N'Devolución de demostración', Monto, Fecha
        FROM    #Dev
        ORDER BY Rk;

        SELECT ROW_NUMBER() OVER (ORDER BY IDDevolucion) AS Rk, IDDevolucion INTO #MapaDev FROM dbo.Devoluciones;

        INSERT INTO dbo.DetalleDevoluciones (IDDevolucion, IDDetallePedido, Cantidad, MontoReembolso)
        SELECT  md.IDDevolucion, dp.IDDetallePedido, dp.CantidadDevuelta,
                CAST(dp.CantidadDevuelta AS DECIMAL(18,2)) * dp.PrecioUnitario
        FROM    #Dev dv
        JOIN    #MapaDev md ON md.Rk = dv.Rk
        JOIN    dbo.DetallePedidos dp ON dp.IDPedido = dv.IDPedido
        WHERE   dp.CantidadDevuelta > 0;

        SELECT  x.*
        INTO    #Mov
        FROM (
            SELECT  l.IDVariante, N'SALIDA' AS Tipo, -l.Cantidad AS Delta, p.Fecha AS Fecha,
                    N'PEDIDO' AS TipoRef, m.IDPedido AS IDRef, p.IDUsuario AS IDUsuarioMov,
                    CONCAT(N'Venta - pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6)) AS Motivo, 1 AS Orden
            FROM    #Lineas l
            JOIN    #Ped p  ON p.n = l.n
            JOIN    #Mapa m ON m.n = l.n
            UNION ALL
            SELECT  l.IDVariante, N'CANCELACION', l.Cantidad, DATEADD(MINUTE, 180, p.Fecha),
                    N'PEDIDO', m.IDPedido, @IDSistema,
                    CONCAT(N'Cancelación del pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6), N': datos de demostración'), 2
            FROM    #Lineas l
            JOIN    #Ped p  ON p.n = l.n
            JOIN    #Mapa m ON m.n = l.n
            WHERE   p.Estado = N'CANCELADO'
            UNION ALL
            SELECT  l.IDVariante, N'DEVOLUCION',
                    CASE WHEN p.Estado = N'DEVUELTO' THEN l.Cantidad ELSE 1 END,
                    dv.Fecha, N'DEVOLUCION', md.IDDevolucion, @IDSistema,
                    CONCAT(N'Devolución del pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6), N': datos de demostración'), 3
            FROM    #Lineas l
            JOIN    #Ped p      ON p.n = l.n
            JOIN    #Mapa m     ON m.n = l.n
            JOIN    #Dev dv     ON dv.n = l.n
            JOIN    #MapaDev md ON md.Rk = dv.Rk
            WHERE   p.Estado = N'DEVUELTO' OR (p.Estado = N'DEVUELTO_PARCIAL' AND l.k = 1)
        ) x;

        INSERT INTO dbo.MovimientosInventario
            (IDVariante, TipoMovimiento, Cantidad, ExistenciaResultante, Motivo, TipoReferencia, IDReferencia, IDUsuario, Fecha)
        SELECT  x.IDVariante, x.Tipo, x.Delta,
                a.Apertura + SUM(x.Delta) OVER (PARTITION BY x.IDVariante
                                                ORDER BY x.Fecha, x.Orden, x.IDRef
                                                ROWS UNBOUNDED PRECEDING),
                x.Motivo, x.TipoRef, x.IDRef, x.IDUsuarioMov, x.Fecha
        FROM    #Mov x
        JOIN    #Apertura a ON a.IDVariante = x.IDVariante
        ORDER BY x.Fecha, x.Orden, x.IDVariante;

        UPDATE v
        SET    v.ExistenciaFisica = k.Total
        FROM   dbo.Variantes v
        JOIN  (SELECT IDVariante, SUM(Cantidad) AS Total
               FROM   dbo.MovimientosInventario
               GROUP BY IDVariante) k ON k.IDVariante = v.IDVariante;

        IF EXISTS (SELECT 1 FROM dbo.VW_Inventario_Conciliacion
                   WHERE DiferenciaFisica <> 0 OR DiferenciaReservada <> 0)
            THROW 50099, N'La conciliación del inventario de demostración presenta diferencias.', 1;

        CREATE TABLE #CartsDemo (Ord INT IDENTITY(1,1) PRIMARY KEY, IDCarrito INT NOT NULL);

        INSERT INTO dbo.Carritos (IDUsuario, TokenHash, FechaCreacion, FechaActualizacion)
        OUTPUT inserted.IDCarrito INTO #CartsDemo (IDCarrito)
        SELECT  cl.IDUsuario, NULL,
                DATEADD(HOUR, -(h.Horas + 2), @Ahora),
                DATEADD(HOUR, -h.Horas, @Ahora)
        FROM    #Clientes cl
        CROSS APPLY (SELECT 3 + ((cl.Ord * 17) % 150) AS Horas) h
        WHERE   cl.Ord BETWEEN 41 AND 54
        ORDER BY cl.Ord;

        INSERT INTO dbo.Carritos (IDUsuario, TokenHash, FechaCreacion, FechaActualizacion)
        OUTPUT inserted.IDCarrito INTO #CartsDemo (IDCarrito)
        SELECT  NULL,
                LOWER(CONVERT(CHAR(64), HASHBYTES('SHA2_256', CONCAT(N'carrito-demo-', g.n)), 2)),
                DATEADD(HOUR, -(h.Horas + 1), @Ahora),
                DATEADD(HOUR, -h.Horas, @Ahora)
        FROM   (VALUES (1), (2), (3), (4)) g (n)
        CROSS APPLY (SELECT 5 + g.n * 31 AS Horas) h
        ORDER BY g.n;

        INSERT INTO dbo.CarritosDetalle (IDCarrito, IDVariante, Cantidad, FechaCreacion)
        SELECT  cd.IDCarrito, pool.IDVariante, 1 + ((cd.Ord + k.k) % 2), c.FechaCreacion
        FROM    #CartsDemo cd
        JOIN    dbo.Carritos c ON c.IDCarrito = cd.IDCarrito
        JOIN    (VALUES (1), (2), (3)) k (k) ON k.k <= 1 + (cd.Ord % 3)
        JOIN    #Pool pool ON pool.Pos = (((cd.Ord * 37) + k.k * 11) % @P) + 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'025_Reportes_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'025_Reportes_Semilla.sql');
GO