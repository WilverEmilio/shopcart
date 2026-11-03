USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.Roles (Nombre, Descripcion)
SELECT v.Nombre, v.Descripcion
FROM (VALUES
    (N'Cliente',       N'Compra y consulta �nicamente su propia informaci�n'),
    (N'Operador',      N'Gestiona pedidos e inventario'),
    (N'Administrador', N'Gestiona adem�s cat�logo, precios, cupones, usuarios y reportes')
) AS v (Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles r WHERE r.Nombre = v.Nombre);
GO

INSERT INTO dbo.Permisos (Codigo, Descripcion)
SELECT v.Codigo, v.Descripcion
FROM (VALUES
    (N'COMPRAR',              N'Carrito, checkout, direcciones y pedidos propios'),
    (N'PEDIDOS_GESTIONAR',    N'Preparar, despachar, avanzar, cancelar y devolver pedidos'),
    (N'INVENTARIO_GESTIONAR', N'Consultar kardex y registrar movimientos y ajustes de inventario'),
    (N'CATALOGO_GESTIONAR',   N'Administrar categor�as, productos y variantes'),
    (N'PRECIOS_GESTIONAR',    N'Modificar precios de las variantes'),
    (N'CUPONES_GESTIONAR',    N'Administrar cupones y promociones'),
    (N'USUARIOS_GESTIONAR',   N'Crear, consultar y desactivar usuarios'),
    (N'REPORTES_VER',         N'Consultar dashboard y reportes'),
    (N'BITACORA_VER',         N'Consultar la bit�cora de auditor�a')
) AS v (Codigo, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = v.Codigo);
GO

INSERT INTO dbo.RolesPermisos (IDRol, IDPermiso)
SELECT r.IDRol, p.IDPermiso
FROM (VALUES
    (N'Cliente',       N'COMPRAR'),

    (N'Operador',      N'PEDIDOS_GESTIONAR'),
    (N'Operador',      N'INVENTARIO_GESTIONAR'),

    (N'Administrador', N'PEDIDOS_GESTIONAR'),
    (N'Administrador', N'INVENTARIO_GESTIONAR'),
    (N'Administrador', N'CATALOGO_GESTIONAR'),
    (N'Administrador', N'PRECIOS_GESTIONAR'),
    (N'Administrador', N'CUPONES_GESTIONAR'),
    (N'Administrador', N'USUARIOS_GESTIONAR'),
    (N'Administrador', N'REPORTES_VER'),
    (N'Administrador', N'BITACORA_VER')
) AS m (Rol, Permiso)
JOIN dbo.Roles    r ON r.Nombre = m.Rol
JOIN dbo.Permisos p ON p.Codigo = m.Permiso
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.RolesPermisos rp
    WHERE rp.IDRol = r.IDRol AND rp.IDPermiso = p.IDPermiso
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'003_Seguridad_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'003_Seguridad_Semilla.sql');
GO

INSERT INTO dbo.Atributos (Nombre)
SELECT v.Nombre
FROM (VALUES (N'Talla'), (N'Color'), (N'Presentaci�n')) AS v (Nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Atributos a WHERE a.Nombre = v.Nombre);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Categorias)
BEGIN
    INSERT INTO dbo.Categorias (Nombre, Descripcion)
    VALUES (N'Ropa',        N'Prendas de vestir para toda la familia'),
           (N'Calzado',     N'Zapatos, tenis y sandalias'),
           (N'Electr�nica', N'Dispositivos y accesorios electr�nicos'),
           (N'Hogar',       N'Art�culos de limpieza y para el hogar'),
           (N'Deportes',    N'Equipo y accesorios deportivos'),
           (N'Juguetes',    N'Juguetes y juegos'),
           (N'Belleza',     N'Cuidado personal y belleza'),
           (N'Papeler�a',   N'�tiles escolares y de oficina');

    DECLARE @P TABLE (Categoria NVARCHAR(100), Nombre NVARCHAR(150), Descripcion NVARCHAR(MAX));
    INSERT INTO @P (Categoria, Nombre, Descripcion) VALUES
        (N'Ropa',        N'Camiseta de algod�n',       N'Camiseta de algod�n 100 % de corte regular.'),
        (N'Ropa',        N'Pantal�n de mezclilla',     N'Pantal�n de mezclilla azul de corte recto.'),
        (N'Calzado',     N'Tenis deportivos',          N'Tenis ligeros para correr y entrenar.'),
        (N'Electr�nica', N'Aud�fonos inal�mbricos',    N'Aud�fonos Bluetooth con estuche de carga.'),
        (N'Hogar',       N'Detergente l�quido',        N'Detergente l�quido concentrado para ropa.'),
        (N'Papeler�a',   N'Libreta universitaria',     N'Libreta de 100 hojas rayadas.');

    INSERT INTO dbo.Productos (IDCategoria, Nombre, Descripcion)
    SELECT c.IDCategoria, p.Nombre, p.Descripcion
    FROM @P p
    JOIN dbo.Categorias c ON c.Nombre = p.Categoria;

    
    DECLARE @V TABLE (Producto NVARCHAR(150), SKU NVARCHAR(50), Precio DECIMAL(12,2),
                      Talla NVARCHAR(50), Color NVARCHAR(50), Presentacion NVARCHAR(50));
    INSERT INTO @V (Producto, SKU, Precio, Talla, Color, Presentacion) VALUES
        (N'Camiseta de algod�n',    N'CAM-ALG-S-NEG',  85.00, N'S',  N'Negro',  NULL),
        (N'Camiseta de algod�n',    N'CAM-ALG-M-NEG',  85.00, N'M',  N'Negro',  NULL),
        (N'Camiseta de algod�n',    N'CAM-ALG-L-NEG',  85.00, N'L',  N'Negro',  NULL),
        (N'Camiseta de algod�n',    N'CAM-ALG-M-BLA',  85.00, N'M',  N'Blanco', NULL),
        (N'Pantal�n de mezclilla',  N'PAN-MEZ-30-AZU', 249.00, N'30', N'Azul',   NULL),
        (N'Pantal�n de mezclilla',  N'PAN-MEZ-32-AZU', 249.00, N'32', N'Azul',   NULL),
        (N'Pantal�n de mezclilla',  N'PAN-MEZ-34-AZU', 249.00, N'34', N'Azul',   NULL),
        (N'Tenis deportivos',       N'TEN-DEP-40-NEG', 399.00, N'40', N'Negro',  NULL),
        (N'Tenis deportivos',       N'TEN-DEP-42-NEG', 399.00, N'42', N'Negro',  NULL),
        (N'Tenis deportivos',       N'TEN-DEP-42-BLA', 399.00, N'42', N'Blanco', NULL),
        (N'Aud�fonos inal�mbricos', N'AUD-INA-NEG',    349.00, NULL,  N'Negro',  NULL),
        (N'Aud�fonos inal�mbricos', N'AUD-INA-BLA',    349.00, NULL,  N'Blanco', NULL),
        (N'Detergente l�quido',     N'DET-LIQ-1L',      32.50, NULL,  NULL,      N'Botella 1 L'),
        (N'Detergente l�quido',     N'DET-LIQ-4L',     105.00, NULL,  NULL,      N'Gal�n 3.8 L'),
        (N'Libreta universitaria',  N'LIB-UNI-100',     18.00, NULL,  NULL,      NULL);

    INSERT INTO dbo.Variantes (IDProducto, SKU, Precio)
    SELECT p.IDProducto, v.SKU, v.Precio
    FROM @V v
    JOIN dbo.Productos p ON p.Nombre = v.Producto;

    INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
    SELECT va.IDVariante, a.IDAtributo, x.Valor
    FROM @V v
    JOIN dbo.Variantes va ON va.SKU = v.SKU
    CROSS APPLY (VALUES (N'Talla', v.Talla), (N'Color', v.Color), (N'Presentaci�n', v.Presentacion)) AS x (Atributo, Valor)
    JOIN dbo.Atributos a ON a.Nombre = x.Atributo
    WHERE x.Valor IS NOT NULL;

    DECLARE @TotalCategorias INT = (SELECT COUNT(*) FROM dbo.Categorias);

    ;WITH N AS (
        SELECT TOP (400) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects a CROSS JOIN sys.all_objects b
    ),
    C AS (
        SELECT IDCategoria, ROW_NUMBER() OVER (ORDER BY IDCategoria) - 1 AS Pos
        FROM dbo.Categorias
    )
    INSERT INTO dbo.Productos (IDCategoria, Nombre, Descripcion)
    SELECT c.IDCategoria,
           CONCAT(N'Art�culo de prueba ', RIGHT(CONCAT(N'0000', N.n), 4)),
           CONCAT(N'Producto generado para pruebas de rendimiento, n�mero ', N.n, N'.')
    FROM N
    JOIN C c ON c.Pos = (N.n - 1) % @TotalCategorias;

    INSERT INTO dbo.Variantes (IDProducto, SKU, Precio)
    SELECT p.IDProducto,
           CONCAT(N'PRB-', RIGHT(CONCAT(N'00000', p.IDProducto), 5), N'-', t.Talla),
           CAST(20 + ((p.IDProducto * 37) % 980) + t.Extra AS DECIMAL(12,2))
    FROM dbo.Productos p
    CROSS JOIN (VALUES (N'S', 0), (N'M', 5), (N'L', 10)) AS t (Talla, Extra)
    WHERE p.Nombre LIKE N'Art�culo de prueba %';

    INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
    SELECT v.IDVariante, a.IDAtributo, RIGHT(v.SKU, 1)
    FROM dbo.Variantes v
    JOIN dbo.Atributos a ON a.Nombre = N'Talla'
    WHERE v.SKU LIKE N'PRB-%';

    INSERT INTO dbo.ImagenesProducto (IDProducto, Url, Orden, EsPrincipal)
    SELECT IDProducto, N'/images/placeholder.svg', 0, 1
    FROM dbo.Productos;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'008_Catalogo_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'008_Catalogo_Semilla.sql');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'sistema@shopcart.local')
    INSERT INTO dbo.Usuarios (IDRol, Correo, PasswordHash, Nombres, Apellidos, Activo)
    SELECT r.IDRol, N'sistema@shopcart.local', N'!SIN-ACCESO', N'Sistema', N'ShopCart', 0
    FROM   dbo.Roles r
    WHERE  r.Nombre = N'Operador';
GO

DECLARE @IDSistema INT = (SELECT IDUsuario FROM dbo.Usuarios WHERE Correo = N'sistema@shopcart.local');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.MovimientosInventario
        (IDVariante, TipoMovimiento, Cantidad, ExistenciaResultante, Motivo, IDUsuario)
    SELECT  v.IDVariante, N'ENTRADA', s.Cantidad, s.Cantidad, N'Carga inicial de inventario', @IDSistema
    FROM    dbo.Variantes v
    CROSS APPLY (
        SELECT CASE WHEN v.SKU = N'TEN-DEP-42-BLA' THEN 1
                    WHEN v.IDVariante % 7 = 0       THEN 0
                    ELSE 20 + (v.IDVariante * 13) % 80 END AS Cantidad
    ) s
    WHERE   s.Cantidad > 0
        AND NOT EXISTS (SELECT 1 FROM dbo.MovimientosInventario m WHERE m.IDVariante = v.IDVariante);

    UPDATE v
    SET    v.ExistenciaFisica = k.Total
    FROM   dbo.Variantes v
    JOIN  (SELECT IDVariante, SUM(Cantidad) AS Total
           FROM   dbo.MovimientosInventario
           GROUP BY IDVariante) k ON k.IDVariante = v.IDVariante;

    IF EXISTS (SELECT 1 FROM dbo.VW_Inventario_Conciliacion
               WHERE DiferenciaFisica <> 0 OR DiferenciaReservada <> 0)
        THROW 50099, N'La conciliaci�n del inventario inicial presenta diferencias.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'012_Inventario_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'012_Inventario_Semilla.sql');
GO

INSERT INTO dbo.Cupones
    (Codigo, Descripcion, TipoDescuento, Valor, IDCategoria, MontoMinimo,
     FechaInicio, FechaFin, LimiteUsosTotal, LimiteUsosPorCliente)
SELECT  v.Codigo, v.Descripcion, v.TipoDescuento, v.Valor, c.IDCategoria, v.MontoMinimo,
        DATEADD(DAY, v.DiasInicio, CAST(SYSUTCDATETIME() AS DATETIME2(0))),
        DATEADD(DAY, v.DiasFin,    CAST(SYSUTCDATETIME() AS DATETIME2(0))),
        v.LimiteTotal, v.LimiteCliente
FROM (VALUES
    (N'BIENVENIDA10', N'10 % de descuento en tu primera compra', N'PORCENTAJE', 10.00, NULL,   100.00,   -1,  90, 100, 1),
    (N'QUETZALES25',  N'Q25 de descuento en compras desde Q250', N'MONTO_FIJO', 25.00, NULL,   250.00,   -1,  60, NULL, 3),
    (N'ROPA15',       N'15 % de descuento en ropa',              N'PORCENTAJE', 15.00, N'Ropa', 0.00,    -1,  45, NULL, 2),
    (N'ULTIMOCUPON',  N'Cup�n de un solo uso para pruebas',      N'PORCENTAJE', 20.00, NULL,    0.00,    -1,  30,    1, 1),
    (N'VENCIDO5',     N'Cup�n vencido para pruebas',             N'PORCENTAJE',  5.00, NULL,    0.00,   -60, -30, NULL, NULL),
    (N'PROXIMAMENTE', N'Cup�n con vigencia futura para pruebas', N'PORCENTAJE', 30.00, NULL,    0.00,    10,  40, NULL, NULL)
) AS v (Codigo, Descripcion, TipoDescuento, Valor, Categoria, MontoMinimo, DiasInicio, DiasFin, LimiteTotal, LimiteCliente)
LEFT JOIN dbo.Categorias c ON c.Nombre = v.Categoria
WHERE NOT EXISTS (SELECT 1 FROM dbo.Cupones x WHERE x.Codigo = v.Codigo);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'017_Cupones_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'017_Cupones_Semilla.sql');
GO

INSERT INTO dbo.MetodosEnvio (Nombre, Descripcion, Costo, DiasEstimados)
SELECT v.Nombre, v.Descripcion, v.Costo, v.DiasEstimados
FROM (VALUES
    (N'Recoger en tienda', N'Retira tu pedido en la tienda sin costo',     0.00, 1),
    (N'Env�o est�ndar',    N'Entrega a domicilio en 3 a 5 d�as h�biles',    35.00, 4),
    (N'Env�o express',     N'Entrega a domicilio al siguiente d�a h�bil',   60.00, 1)
) AS v (Nombre, Descripcion, Costo, DiasEstimados)
WHERE NOT EXISTS (SELECT 1 FROM dbo.MetodosEnvio m WHERE m.Nombre = v.Nombre);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'019_Checkout_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'019_Checkout_Semilla.sql');
GO

INSERT INTO dbo.TransicionesEstadoPedido (EstadoOrigen, EstadoDestino)
SELECT v.Origen, v.Destino
FROM (VALUES
    (N'PAGADO',           N'EN_PREPARACION'),
    (N'PAGADO',           N'CANCELADO'),
    (N'EN_PREPARACION',   N'DESPACHADO'),
    (N'EN_PREPARACION',   N'CANCELADO'),
    (N'DESPACHADO',       N'ENTREGADO'),
    (N'ENTREGADO',        N'DEVUELTO_PARCIAL'),
    (N'ENTREGADO',        N'DEVUELTO'),
    (N'DEVUELTO_PARCIAL', N'DEVUELTO')
) AS v (Origen, Destino)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.TransicionesEstadoPedido t
    WHERE t.EstadoOrigen = v.Origen AND t.EstadoDestino = v.Destino
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'022_Gestion_Pedidos_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'022_Gestion_Pedidos_Semilla.sql');
GO

INSERT INTO dbo.Configuracion (Clave, Valor, Descripcion)
SELECT v.Clave, v.Valor, v.Descripcion
FROM (VALUES
    (N'OffsetHorasLocal',    N'-6',  N'Diferencia en horas entre la hora local (Guatemala) y UTC; se usa para agrupar los reportes por d�a'),
    (N'AbandonoCarritoHoras', N'24', N'Horas sin actividad para considerar abandonado un carrito con productos')
) AS v (Clave, Valor, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Configuracion c WHERE c.Clave = v.Clave);
GO

INSERT INTO dbo.Permisos (Codigo, Descripcion)
SELECT N'CONFIGURACION_GESTIONAR', N'Consultar y modificar la configuraci�n del sistema'
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
            SELECT Id, Nombre FROM (VALUES (0, N'Mar�a'), (1, N'Jos�'), (2, N'Ana'), (3, N'Luis'), (4, N'Carmen'),
                                           (5, N'Carlos'), (6, N'Sof�a'), (7, N'Diego'), (8, N'Luc�a'), (9, N'Miguel')) x (Id, Nombre)
        ),
        Apellidos (Id, Apellido) AS (
            SELECT Id, Apellido FROM (VALUES (0, N'L�pez'), (1, N'Garc�a'), (2, N'P�rez'), (3, N'Morales'),
                                             (4, N'Hern�ndez'), (5, N'Aj�')) x (Id, Apellido)
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
            THROW 50099, N'Faltan clientes de demostraci�n o m�todos de env�o (ejecute el script 019).', 1;

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
                N'Reposici�n de temporada (datos de demostraci�n)', @IDSistema, @InicioRepo
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
                CASE WHEN s.Orden = 1 THEN N'Pedido creado con pago aprobado' ELSE N'Datos de demostraci�n' END
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
        SELECT  IDPedido, @IDSistema, N'Devoluci�n de demostraci�n', Monto, Fecha
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
                    CONCAT(N'Cancelaci�n del pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6), N': datos de demostraci�n'), 2
            FROM    #Lineas l
            JOIN    #Ped p  ON p.n = l.n
            JOIN    #Mapa m ON m.n = l.n
            WHERE   p.Estado = N'CANCELADO'
            UNION ALL
            SELECT  l.IDVariante, N'DEVOLUCION',
                    CASE WHEN p.Estado = N'DEVUELTO' THEN l.Cantidad ELSE 1 END,
                    dv.Fecha, N'DEVOLUCION', md.IDDevolucion, @IDSistema,
                    CONCAT(N'Devoluci�n del pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6), N': datos de demostraci�n'), 3
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
            THROW 50099, N'La conciliaci�n del inventario de demostraci�n presenta diferencias.', 1;

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