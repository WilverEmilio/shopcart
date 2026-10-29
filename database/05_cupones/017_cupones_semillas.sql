/* =============================================================================
   017_Cupones_Semilla.sql
   Cupones de ejemplo, uno por cada caso que debe probarse:
     BIENVENIDA10   10 % a todo el carrito, mínimo Q100, 1 uso por cliente
     QUETZALES25    Q25 de descuento, mínimo Q250 (prueba "monto mínimo")
     ROPA15         15 % solo a la categoría Ropa (prueba descuento por categoría)
     ULTIMOCUPON    límite total = 1 (prueba "agotado" y el uso simultáneo)
     VENCIDO5       vigencia ya terminada (prueba "vencido")
     PROXIMAMENTE   vigencia futura (prueba "aún no vigente")
   Las fechas son relativas a hoy y se guardan en UTC. Reejecutable.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
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
    (N'ULTIMOCUPON',  N'Cupón de un solo uso para pruebas',      N'PORCENTAJE', 20.00, NULL,    0.00,    -1,  30,    1, 1),
    (N'VENCIDO5',     N'Cupón vencido para pruebas',             N'PORCENTAJE',  5.00, NULL,    0.00,   -60, -30, NULL, NULL),
    (N'PROXIMAMENTE', N'Cupón con vigencia futura para pruebas', N'PORCENTAJE', 30.00, NULL,    0.00,    10,  40, NULL, NULL)
) AS v (Codigo, Descripcion, TipoDescuento, Valor, Categoria, MontoMinimo, DiasInicio, DiasFin, LimiteTotal, LimiteCliente)
LEFT JOIN dbo.Categorias c ON c.Nombre = v.Categoria
WHERE NOT EXISTS (SELECT 1 FROM dbo.Cupones x WHERE x.Codigo = v.Codigo);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'017_Cupones_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'017_Cupones_Semilla.sql');
GO