/* =============================================================================
   008_Catalogo_Semilla.sql
   Atributos, categorías, 6 productos curados y 400 productos de prueba
   (1,200 variantes) para validar rendimiento de listados y búsquedas.

   Las existencias quedan en 0 a propósito: el módulo de inventario cargará el
   stock inicial mediante movimientos del kardex, para que la existencia
   siempre coincida con la suma de movimientos.
   Reejecutable: no inserta nada si ya existen categorías.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.Atributos (Nombre)
SELECT v.Nombre
FROM (VALUES (N'Talla'), (N'Color'), (N'Presentación')) AS v (Nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Atributos a WHERE a.Nombre = v.Nombre);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Categorias)
BEGIN
    INSERT INTO dbo.Categorias (Nombre, Descripcion)
    VALUES (N'Ropa',        N'Prendas de vestir para toda la familia'),
           (N'Calzado',     N'Zapatos, tenis y sandalias'),
           (N'Electrónica', N'Dispositivos y accesorios electrónicos'),
           (N'Hogar',       N'Artículos de limpieza y para el hogar'),
           (N'Deportes',    N'Equipo y accesorios deportivos'),
           (N'Juguetes',    N'Juguetes y juegos'),
           (N'Belleza',     N'Cuidado personal y belleza'),
           (N'Papelería',   N'Útiles escolares y de oficina');

    DECLARE @P TABLE (Categoria NVARCHAR(100), Nombre NVARCHAR(150), Descripcion NVARCHAR(MAX));
    INSERT INTO @P (Categoria, Nombre, Descripcion) VALUES
        (N'Ropa',        N'Camiseta de algodón',       N'Camiseta de algodón 100 % de corte regular.'),
        (N'Ropa',        N'Pantalón de mezclilla',     N'Pantalón de mezclilla azul de corte recto.'),
        (N'Calzado',     N'Tenis deportivos',          N'Tenis ligeros para correr y entrenar.'),
        (N'Electrónica', N'Audífonos inalámbricos',    N'Audífonos Bluetooth con estuche de carga.'),
        (N'Hogar',       N'Detergente líquido',        N'Detergente líquido concentrado para ropa.'),
        (N'Papelería',   N'Libreta universitaria',     N'Libreta de 100 hojas rayadas.');

    INSERT INTO dbo.Productos (IDCategoria, Nombre, Descripcion)
    SELECT c.IDCategoria, p.Nombre, p.Descripcion
    FROM @P p
    JOIN dbo.Categorias c ON c.Nombre = p.Categoria;

    
    DECLARE @V TABLE (Producto NVARCHAR(150), SKU NVARCHAR(50), Precio DECIMAL(12,2),
                      Talla NVARCHAR(50), Color NVARCHAR(50), Presentacion NVARCHAR(50));
    INSERT INTO @V (Producto, SKU, Precio, Talla, Color, Presentacion) VALUES
        (N'Camiseta de algodón',    N'CAM-ALG-S-NEG',  85.00, N'S',  N'Negro',  NULL),
        (N'Camiseta de algodón',    N'CAM-ALG-M-NEG',  85.00, N'M',  N'Negro',  NULL),
        (N'Camiseta de algodón',    N'CAM-ALG-L-NEG',  85.00, N'L',  N'Negro',  NULL),
        (N'Camiseta de algodón',    N'CAM-ALG-M-BLA',  85.00, N'M',  N'Blanco', NULL),
        (N'Pantalón de mezclilla',  N'PAN-MEZ-30-AZU', 249.00, N'30', N'Azul',   NULL),
        (N'Pantalón de mezclilla',  N'PAN-MEZ-32-AZU', 249.00, N'32', N'Azul',   NULL),
        (N'Pantalón de mezclilla',  N'PAN-MEZ-34-AZU', 249.00, N'34', N'Azul',   NULL),
        (N'Tenis deportivos',       N'TEN-DEP-40-NEG', 399.00, N'40', N'Negro',  NULL),
        (N'Tenis deportivos',       N'TEN-DEP-42-NEG', 399.00, N'42', N'Negro',  NULL),
        (N'Tenis deportivos',       N'TEN-DEP-42-BLA', 399.00, N'42', N'Blanco', NULL),
        (N'Audífonos inalámbricos', N'AUD-INA-NEG',    349.00, NULL,  N'Negro',  NULL),
        (N'Audífonos inalámbricos', N'AUD-INA-BLA',    349.00, NULL,  N'Blanco', NULL),
        (N'Detergente líquido',     N'DET-LIQ-1L',      32.50, NULL,  NULL,      N'Botella 1 L'),
        (N'Detergente líquido',     N'DET-LIQ-4L',     105.00, NULL,  NULL,      N'Galón 3.8 L'),
        (N'Libreta universitaria',  N'LIB-UNI-100',     18.00, NULL,  NULL,      NULL);

    INSERT INTO dbo.Variantes (IDProducto, SKU, Precio)
    SELECT p.IDProducto, v.SKU, v.Precio
    FROM @V v
    JOIN dbo.Productos p ON p.Nombre = v.Producto;

    INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
    SELECT va.IDVariante, a.IDAtributo, x.Valor
    FROM @V v
    JOIN dbo.Variantes va ON va.SKU = v.SKU
    CROSS APPLY (VALUES (N'Talla', v.Talla), (N'Color', v.Color), (N'Presentación', v.Presentacion)) AS x (Atributo, Valor)
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
           CONCAT(N'Artículo de prueba ', RIGHT(CONCAT(N'0000', N.n), 4)),
           CONCAT(N'Producto generado para pruebas de rendimiento, número ', N.n, N'.')
    FROM N
    JOIN C c ON c.Pos = (N.n - 1) % @TotalCategorias;

    INSERT INTO dbo.Variantes (IDProducto, SKU, Precio)
    SELECT p.IDProducto,
           CONCAT(N'PRB-', RIGHT(CONCAT(N'00000', p.IDProducto), 5), N'-', t.Talla),
           CAST(20 + ((p.IDProducto * 37) % 980) + t.Extra AS DECIMAL(12,2))
    FROM dbo.Productos p
    CROSS JOIN (VALUES (N'S', 0), (N'M', 5), (N'L', 10)) AS t (Talla, Extra)
    WHERE p.Nombre LIKE N'Artículo de prueba %';

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