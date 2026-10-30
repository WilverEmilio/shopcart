/* =============================================================================
   024_Reportes_Tablas.sql
   Módulo 8 - Dashboard y reportes: Configuracion y vistas de apoyo.

   DEFINICIÓN DE "VENTA" (documentar en el README):
     - Se cuentan los pedidos PAGADOS y no cancelados. Se excluyen CANCELADO y
       DEVUELTO (devuelto en su totalidad).
     - Venta neta del pedido = Total - devoluciones registradas. La devolución se
       descuenta del periodo en que se hizo el pedido original.
     - Ticket promedio = venta neta / número de pedidos del periodo.
     - Las ventas por categoría y por producto se calculan sobre las líneas
       (sin envío) y usan la categoría vigente del producto.
     - Las fechas se agrupan en HORA LOCAL (Configuracion.OffsetHorasLocal,
       -6 para Guatemala); en la base de datos todo se guarda en UTC.
   Las vistas solo se consultan desde stored procedures.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE TABLE dbo.Configuracion (
    Clave              NVARCHAR(50)  NOT NULL CONSTRAINT PK_Configuracion PRIMARY KEY,
    Valor              NVARCHAR(100) NOT NULL,
    Descripcion        NVARCHAR(255) NOT NULL,
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Configuracion_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Configuracion_Offset  CHECK (Clave <> N'OffsetHorasLocal'    OR TRY_CAST(Valor AS INT) BETWEEN -12 AND 14),
    CONSTRAINT CK_Configuracion_Abandono CHECK (Clave <> N'AbandonoCarritoHoras' OR TRY_CAST(Valor AS INT) BETWEEN 1 AND 720)
);
GO

CREATE OR ALTER VIEW dbo.VW_Dashboard_VentasPorPedido
AS
SELECT  p.IDPedido,
        p.IDUsuario,
        p.Estado,
        p.FechaCreacion,
        CAST(DATEADD(HOUR, cfg.Offset, p.FechaCreacion) AS DATE) AS FechaLocal,
        p.Total,
        ISNULL(d.Devuelto, 0)                  AS Devuelto,
        p.Total - ISNULL(d.Devuelto, 0)        AS VentaNeta
FROM    dbo.Pedidos p
CROSS JOIN (SELECT ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                           WHERE Clave = N'OffsetHorasLocal'), -6) AS Offset) cfg
LEFT JOIN (SELECT IDPedido, SUM(MontoReembolso) AS Devuelto
           FROM   dbo.Devoluciones
           GROUP BY IDPedido) d ON d.IDPedido = p.IDPedido
WHERE   p.Estado NOT IN (N'CANCELADO', N'DEVUELTO');
GO

CREATE OR ALTER VIEW dbo.VW_Dashboard_VentasPorLinea
AS
SELECT  d.IDDetallePedido,
        d.IDPedido,
        p.FechaCreacion,
        CAST(DATEADD(HOUR, cfg.Offset, p.FechaCreacion) AS DATE) AS FechaLocal,
        d.IDVariante,
        pr.IDProducto,
        pr.Nombre                               AS Producto,
        c.IDCategoria,
        c.Nombre                                AS Categoria,
        d.Cantidad - d.CantidadDevuelta         AS UnidadesNetas,
        d.Subtotal - d.DescuentoLinea - ISNULL(dd.Devuelto, 0) AS VentaNeta
FROM    dbo.DetallePedidos d
JOIN    dbo.Pedidos p     ON p.IDPedido = d.IDPedido
JOIN    dbo.Variantes v   ON v.IDVariante = d.IDVariante
JOIN    dbo.Productos pr  ON pr.IDProducto = v.IDProducto
JOIN    dbo.Categorias c  ON c.IDCategoria = pr.IDCategoria
CROSS JOIN (SELECT ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                           WHERE Clave = N'OffsetHorasLocal'), -6) AS Offset) cfg
LEFT JOIN (SELECT IDDetallePedido, SUM(MontoReembolso) AS Devuelto
           FROM   dbo.DetalleDevoluciones
           GROUP BY IDDetallePedido) dd ON dd.IDDetallePedido = d.IDDetallePedido
WHERE   p.Estado NOT IN (N'CANCELADO', N'DEVUELTO');
GO

CREATE OR ALTER VIEW dbo.VW_Pedidos_Historial
AS
SELECT  p.IDPedido,
        p.NumeroPedido,
        p.Estado,
        p.IDUsuario,
        u.Correo                                AS CorreoCliente,
        CONCAT(u.Nombres, N' ', u.Apellidos)    AS NombreCliente,
        p.Total,
        ISNULL(d.Devuelto, 0)                   AS Devuelto,
        p.NombreEnvio,
        p.CodigoCupon,
        p.FechaCreacion,
        p.FechaActualizacion
FROM    dbo.Pedidos p
JOIN    dbo.Usuarios u ON u.IDUsuario = p.IDUsuario
LEFT JOIN (SELECT IDPedido, SUM(MontoReembolso) AS Devuelto
           FROM   dbo.Devoluciones
           GROUP BY IDPedido) d ON d.IDPedido = p.IDPedido;
GO

CREATE OR ALTER VIEW dbo.VW_Dashboard_CarritosAbandonados
AS
SELECT  c.IDCarrito,
        c.IDUsuario,
        CASE WHEN c.IDUsuario IS NULL THEN N'Invitado' ELSE u.Correo END AS Cliente,
        CAST(CASE WHEN c.IDUsuario IS NULL THEN 1 ELSE 0 END AS BIT)     AS EsInvitado,
        c.FechaCreacion,
        c.FechaActualizacion,
        DATEDIFF(HOUR, c.FechaActualizacion, SYSUTCDATETIME())           AS HorasInactivo,
        x.Lineas,
        x.Unidades,
        x.Valor
FROM    dbo.Carritos c
LEFT JOIN dbo.Usuarios u ON u.IDUsuario = c.IDUsuario
CROSS JOIN (SELECT ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                           WHERE Clave = N'AbandonoCarritoHoras'), 24) AS Horas) cfg
CROSS APPLY (
        SELECT  COUNT(*) AS Lineas,
                ISNULL(SUM(d.Cantidad), 0) AS Unidades,
                CAST(ISNULL(SUM(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio), 0) AS DECIMAL(18,2)) AS Valor
        FROM    dbo.CarritosDetalle d
        JOIN    dbo.Variantes v ON v.IDVariante = d.IDVariante
        WHERE   d.IDCarrito = c.IDCarrito
) x
WHERE   c.Estado = N'ACTIVO'
    AND x.Lineas > 0
    AND c.FechaActualizacion < DATEADD(HOUR, -cfg.Horas, SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'024_Reportes_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'024_Reportes_Tablas.sql');
GO