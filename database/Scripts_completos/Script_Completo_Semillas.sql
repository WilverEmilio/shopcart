USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.Roles (Nombre, Descripcion)
SELECT v.Nombre, v.Descripcion
FROM (VALUES
    (N'Cliente',       N'Compra y consulta únicamente su propia información'),
    (N'Operador',      N'Gestiona pedidos e inventario'),
    (N'Administrador', N'Gestiona además catálogo, precios, cupones, usuarios y reportes')
) AS v (Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles r WHERE r.Nombre = v.Nombre);
GO

INSERT INTO dbo.Permisos (Codigo, Descripcion)
SELECT v.Codigo, v.Descripcion
FROM (VALUES
    (N'COMPRAR',              N'Carrito, checkout, direcciones y pedidos propios'),
    (N'PEDIDOS_GESTIONAR',    N'Preparar, despachar, avanzar, cancelar y devolver pedidos'),
    (N'INVENTARIO_GESTIONAR', N'Consultar kardex y registrar movimientos y ajustes de inventario'),
    (N'CATALOGO_GESTIONAR',   N'Administrar categorías, productos y variantes'),
    (N'PRECIOS_GESTIONAR',    N'Modificar precios de las variantes'),
    (N'CUPONES_GESTIONAR',    N'Administrar cupones y promociones'),
    (N'USUARIOS_GESTIONAR',   N'Crear, consultar y desactivar usuarios'),
    (N'REPORTES_VER',         N'Consultar dashboard y reportes'),
    (N'BITACORA_VER',         N'Consultar la bitácora de auditoría')
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
FROM (VALUES (N'Talla'), (N'Color'), (N'Presentación')) AS v (Nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Atributos a WHERE a.Nombre = v.Nombre);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Categorias)
BEGIN
    INSERT INTO dbo.Categorias (Nombre, Descripcion)
    VALUES (N'Ropa',        N'Prendas de vestir para dama, caballero y toda la familia'),
           (N'Calzado',     N'Tenis, zapatos, botas y sandalias'),
           (N'Electrónica', N'Audio, carga, computación y accesorios'),
           (N'Hogar',       N'Cocina, recámara, baño y limpieza'),
           (N'Deportes',    N'Equipo para entrenar en casa y al aire libre'),
           (N'Juguetes',    N'Juguetes, rompecabezas y juegos de mesa'),
           (N'Belleza',     N'Cuidado personal, de la piel y del cabello'),
           (N'Papelería',   N'Útiles escolares y de oficina');

    /* Orden explícito para que los ID de productos y variantes sean siempre los mismos. */
    DECLARE @P TABLE (Orden INT, Categoria NVARCHAR(100), Nombre NVARCHAR(150), Descripcion NVARCHAR(MAX));
    INSERT INTO @P (Orden, Categoria, Nombre, Descripcion) VALUES
        ( 1, N'Ropa', N'Camiseta de algodón', N'Camiseta de algodón peinado 100 % de corte regular, cuello redondo reforzado y costuras dobles. Fresca para el clima de todo el año.'),
        ( 2, N'Ropa', N'Pantalón de mezclilla', N'Pantalón de mezclilla azul de corte recto con 2 % de elastano para mayor comodidad. Cinco bolsillos y botón metálico.'),
        ( 3, N'Calzado', N'Tenis deportivos', N'Tenis ligeros para correr y entrenar, con suela de goma antideslizante y plantilla acolchada removible.'),
        ( 4, N'Electrónica', N'Audífonos inalámbricos', N'Audífonos Bluetooth 5.3 con estuche de carga, hasta 24 horas de batería en total y resistencia al sudor IPX4.'),
        ( 5, N'Hogar', N'Detergente líquido', N'Detergente líquido concentrado para ropa blanca y de color. Rinde hasta 30 lavadas por litro.'),
        ( 6, N'Papelería', N'Libreta universitaria', N'Libreta universitaria de 100 hojas rayadas con espiral doble y pasta dura.'),
        ( 7, N'Ropa', N'Sudadera con capucha unisex', N'Sudadera de felpa perchada con capucha ajustable y bolsillo tipo canguro. Ideal para las mañanas frías.'),
        ( 8, N'Ropa', N'Blusa de lino manga corta', N'Blusa de lino ligero con botones al frente y corte holgado. Transpirable y fácil de combinar.'),
        ( 9, N'Ropa', N'Chaqueta rompevientos impermeable', N'Chaqueta liviana con tratamiento repelente al agua, capucha plegable en el cuello y bolsillos con cierre.'),
        (10, N'Ropa', N'Vestido casual estampado', N'Vestido midi de viscosa con estampado floral, cintura elástica y tirantes ajustables.'),
        (11, N'Ropa', N'Polo piqué para hombre', N'Camisa tipo polo en tejido piqué de algodón, cuello tejido y dos botones.'),
        (12, N'Calzado', N'Sandalias de playa', N'Sandalias de EVA ultraligeras, resistentes al agua y con correa acolchada.'),
        (13, N'Calzado', N'Botas de cuero para trabajo', N'Botas de cuero genuino con puntera reforzada, suela antideslizante y costura resistente.'),
        (14, N'Calzado', N'Zapatos casuales de lona', N'Zapatos de lona con suela vulcanizada y plantilla acolchada, cómodos para el día a día.'),
        (15, N'Calzado', N'Mocasines de cuero', N'Mocasines de cuero flexible con forro interior suave, para oficina o eventos.'),
        (16, N'Electrónica', N'Cargador rápido USB-C 20 W', N'Cargador de pared con un puerto USB-C de 20 W compatible con carga rápida para teléfonos y tabletas.'),
        (17, N'Electrónica', N'Bocina Bluetooth portátil', N'Bocina resistente al agua IPX7 con 12 horas de batería, micrófono para llamadas y correa para colgar.'),
        (18, N'Electrónica', N'Batería portátil 10,000 mAh', N'Batería externa delgada con salida USB-C y USB-A; carga un teléfono hasta dos veces.'),
        (19, N'Electrónica', N'Mouse inalámbrico ergonómico', N'Mouse silencioso de 2.4 GHz con receptor USB, 1,600 DPI y diseño ergonómico para uso prolongado.'),
        (20, N'Electrónica', N'Teclado mecánico compacto', N'Teclado mecánico de 87 teclas con interruptores rojos, retroiluminación blanca y cable USB-C desmontable.'),
        (21, N'Electrónica', N'Cable USB-C a USB-C', N'Cable trenzado de nailon con carga de hasta 60 W y transferencia de datos.'),
        (22, N'Electrónica', N'Reloj inteligente deportivo', N'Reloj con monitor de ritmo cardíaco, conteo de pasos, notificaciones y hasta 7 días de batería.'),
        (23, N'Hogar', N'Juego de sábanas de algodón', N'Juego de sábana bajera, sábana plana y dos fundas de algodón de 200 hilos.'),
        (24, N'Hogar', N'Sartén antiadherente', N'Sartén de aluminio forjado con recubrimiento antiadherente libre de PFOA y mango de baquelita.'),
        (25, N'Hogar', N'Juego de toallas de baño', N'Set de 3 toallas de algodón absorbente: baño, manos y cara.'),
        (26, N'Hogar', N'Cafetera de goteo 12 tazas', N'Cafetera eléctrica con jarra de vidrio, placa para mantener caliente y filtro permanente lavable.'),
        (27, N'Hogar', N'Lámpara de escritorio LED', N'Lámpara LED con brazo flexible, tres tonos de luz y puerto USB para cargar el teléfono.'),
        (28, N'Hogar', N'Set de recipientes herméticos', N'Diez recipientes de plástico libre de BPA con tapa hermética, aptos para microondas y congelador.'),
        (29, N'Deportes', N'Balón de fútbol', N'Balón cosido a máquina con cámara de butilo, ideal para grama natural o sintética.'),
        (30, N'Deportes', N'Mat de yoga antideslizante', N'Mat de 6 mm de grosor con superficie texturizada antideslizante y correa para transportarlo.'),
        (31, N'Deportes', N'Botella térmica de acero', N'Botella de acero inoxidable de doble pared, 750 ml. Mantiene bebidas frías 24 horas y calientes 12.'),
        (32, N'Deportes', N'Par de mancuernas de neopreno', N'Par de mancuernas con recubrimiento de neopreno antideslizante, para entrenar en casa.'),
        (33, N'Deportes', N'Cuerda para saltar ajustable', N'Cuerda de acero recubierto con rodamientos y mangos de espuma; largo ajustable.'),
        (34, N'Juguetes', N'Bloques de construcción 500 piezas', N'Set de 500 bloques compatibles en colores surtidos con caja organizadora. Para mayores de 6 años.'),
        (35, N'Juguetes', N'Rompecabezas de Antigua Guatemala', N'Rompecabezas de 1,000 piezas con una vista del Arco de Santa Catalina. Medida armado: 70 × 50 cm.'),
        (36, N'Juguetes', N'Carro a control remoto todoterreno', N'Carro 4x4 escala 1:18 con batería recargable y control de 2.4 GHz; alcanza hasta 20 km/h.'),
        (37, N'Juguetes', N'Muñeca articulada con accesorios', N'Muñeca con 11 puntos de articulación, dos mudas de ropa y accesorios intercambiables.'),
        (38, N'Juguetes', N'Juego de mesa de estrategia', N'Juego de mesa familiar para 2 a 5 jugadores, partidas de 45 minutos. Para mayores de 10 años.'),
        (39, N'Belleza', N'Protector solar FPS 50', N'Protector solar de amplio espectro, resistente al agua y de textura ligera no grasosa.'),
        (40, N'Belleza', N'Champú con keratina', N'Champú reparador con keratina para cabello seco o dañado, sin sales ni parabenos.'),
        (41, N'Belleza', N'Crema hidratante facial', N'Crema facial con ácido hialurónico para piel normal a mixta, de uso diario.'),
        (42, N'Belleza', N'Kit de brochas de maquillaje', N'Doce brochas de cerdas sintéticas suaves con estuche enrollable.'),
        (43, N'Belleza', N'Perfume floral para dama', N'Eau de parfum con notas de jazmín, pera y vainilla.'),
        (44, N'Papelería', N'Bolígrafos de gel 12 colores', N'Set de 12 bolígrafos de tinta gel de punta fina 0.7 mm en colores surtidos.'),
        (45, N'Papelería', N'Mochila escolar con compartimento para laptop', N'Mochila de poliéster resistente al agua con compartimento acolchado para laptop de hasta 15.6 pulgadas.'),
        (46, N'Papelería', N'Calculadora científica', N'Calculadora científica de 240 funciones con pantalla de dos líneas y tapa protectora.'),
        (47, N'Papelería', N'Resma de papel bond', N'Resma de 500 hojas de papel bond blanco de 75 g.'),
        (48, N'Papelería', N'Marcadores fluorescentes', N'Set de 6 marcadores fluorescentes de punta biselada en colores surtidos.');

    INSERT INTO dbo.Productos (IDCategoria, Nombre, Descripcion)
    SELECT c.IDCategoria, p.Nombre, p.Descripcion
    FROM @P p
    JOIN dbo.Categorias c ON c.Nombre = p.Categoria
    ORDER BY p.Orden;

    DECLARE @V TABLE (Orden INT, Producto NVARCHAR(150), SKU NVARCHAR(50), Precio DECIMAL(12,2),
                      Talla NVARCHAR(50), Color NVARCHAR(50), Presentacion NVARCHAR(50));
    INSERT INTO @V (Orden, Producto, SKU, Precio, Talla, Color, Presentacion) VALUES
        (  1, N'Camiseta de algodón', N'CAM-ALG-S-NEG',   85.00, N'S', N'Negro', NULL),
        (  2, N'Camiseta de algodón', N'CAM-ALG-M-NEG',   85.00, N'M', N'Negro', NULL),
        (  3, N'Camiseta de algodón', N'CAM-ALG-L-NEG',   85.00, N'L', N'Negro', NULL),
        (  4, N'Camiseta de algodón', N'CAM-ALG-M-BLA',   85.00, N'M', N'Blanco', NULL),
        (  5, N'Pantalón de mezclilla', N'PAN-MEZ-30-AZU',  249.00, N'30', N'Azul', NULL),
        (  6, N'Pantalón de mezclilla', N'PAN-MEZ-32-AZU',  249.00, N'32', N'Azul', NULL),
        (  7, N'Pantalón de mezclilla', N'PAN-MEZ-34-AZU',  249.00, N'34', N'Azul', NULL),
        (  8, N'Tenis deportivos', N'TEN-DEP-40-NEG',  399.00, N'40', N'Negro', NULL),
        (  9, N'Tenis deportivos', N'TEN-DEP-42-NEG',  399.00, N'42', N'Negro', NULL),
        ( 10, N'Tenis deportivos', N'TEN-DEP-42-BLA',  399.00, N'42', N'Blanco', NULL),
        ( 11, N'Audífonos inalámbricos', N'AUD-INA-NEG',  349.00, NULL, N'Negro', NULL),
        ( 12, N'Audífonos inalámbricos', N'AUD-INA-BLA',  349.00, NULL, N'Blanco', NULL),
        ( 13, N'Detergente líquido', N'DET-LIQ-1L',   32.50, NULL, NULL, N'Botella 1 L'),
        ( 14, N'Detergente líquido', N'DET-LIQ-4L',  105.00, NULL, NULL, N'Galón 3.8 L'),
        ( 15, N'Libreta universitaria', N'LIB-UNI-100',   18.00, NULL, NULL, NULL),
        ( 16, N'Sudadera con capucha unisex', N'SUD-CAP-S-GRI',  219.00, N'S', N'Gris jaspeado', NULL),
        ( 17, N'Sudadera con capucha unisex', N'SUD-CAP-M-GRI',  219.00, N'M', N'Gris jaspeado', NULL),
        ( 18, N'Sudadera con capucha unisex', N'SUD-CAP-L-GRI',  219.00, N'L', N'Gris jaspeado', NULL),
        ( 19, N'Sudadera con capucha unisex', N'SUD-CAP-M-AZM',  219.00, N'M', N'Azul marino', NULL),
        ( 20, N'Sudadera con capucha unisex', N'SUD-CAP-L-AZM',  219.00, N'L', N'Azul marino', NULL),
        ( 21, N'Blusa de lino manga corta', N'BLU-LIN-S-BLA',  179.00, N'S', N'Blanco', NULL),
        ( 22, N'Blusa de lino manga corta', N'BLU-LIN-M-BLA',  179.00, N'M', N'Blanco', NULL),
        ( 23, N'Blusa de lino manga corta', N'BLU-LIN-L-BLA',  179.00, N'L', N'Blanco', NULL),
        ( 24, N'Blusa de lino manga corta', N'BLU-LIN-M-BEI',  179.00, N'M', N'Beige', NULL),
        ( 25, N'Chaqueta rompevientos impermeable', N'CHA-ROM-M-NEG',  329.00, N'M', N'Negro', NULL),
        ( 26, N'Chaqueta rompevientos impermeable', N'CHA-ROM-L-NEG',  329.00, N'L', N'Negro', NULL),
        ( 27, N'Chaqueta rompevientos impermeable', N'CHA-ROM-M-VER',  329.00, N'M', N'Verde olivo', NULL),
        ( 28, N'Vestido casual estampado', N'VES-CAS-S-FLO',  259.00, N'S', N'Floral', NULL),
        ( 29, N'Vestido casual estampado', N'VES-CAS-M-FLO',  259.00, N'M', N'Floral', NULL),
        ( 30, N'Vestido casual estampado', N'VES-CAS-L-FLO',  259.00, N'L', N'Floral', NULL),
        ( 31, N'Polo piqué para hombre', N'POL-PIQ-M-AZM',  149.00, N'M', N'Azul marino', NULL),
        ( 32, N'Polo piqué para hombre', N'POL-PIQ-L-AZM',  149.00, N'L', N'Azul marino', NULL),
        ( 33, N'Polo piqué para hombre', N'POL-PIQ-XL-AZM',  149.00, N'XL', N'Azul marino', NULL),
        ( 34, N'Polo piqué para hombre', N'POL-PIQ-L-BLA',  149.00, N'L', N'Blanco', NULL),
        ( 35, N'Sandalias de playa', N'SAN-PLA-38-NEG',   89.00, N'38', N'Negro', NULL),
        ( 36, N'Sandalias de playa', N'SAN-PLA-40-NEG',   89.00, N'40', N'Negro', NULL),
        ( 37, N'Sandalias de playa', N'SAN-PLA-42-NEG',   89.00, N'42', N'Negro', NULL),
        ( 38, N'Botas de cuero para trabajo', N'BOT-CUE-40-CAF',  589.00, N'40', N'Café', NULL),
        ( 39, N'Botas de cuero para trabajo', N'BOT-CUE-42-CAF',  589.00, N'42', N'Café', NULL),
        ( 40, N'Botas de cuero para trabajo', N'BOT-CUE-44-CAF',  589.00, N'44', N'Café', NULL),
        ( 41, N'Zapatos casuales de lona', N'ZAP-LON-38-BLA',  189.00, N'38', N'Blanco', NULL),
        ( 42, N'Zapatos casuales de lona', N'ZAP-LON-40-BLA',  189.00, N'40', N'Blanco', NULL),
        ( 43, N'Zapatos casuales de lona', N'ZAP-LON-42-AZM',  189.00, N'42', N'Azul marino', NULL),
        ( 44, N'Mocasines de cuero', N'MOC-CUE-40-CAF',  449.00, N'40', N'Café', NULL),
        ( 45, N'Mocasines de cuero', N'MOC-CUE-41-CAF',  449.00, N'41', N'Café', NULL),
        ( 46, N'Mocasines de cuero', N'MOC-CUE-42-NEG',  449.00, N'42', N'Negro', NULL),
        ( 47, N'Cargador rápido USB-C 20 W', N'CAR-USC-20W',  129.00, NULL, N'Blanco', NULL),
        ( 48, N'Bocina Bluetooth portátil', N'BOC-BLU-NEG',  299.00, NULL, N'Negro', NULL),
        ( 49, N'Bocina Bluetooth portátil', N'BOC-BLU-AZU',  299.00, NULL, N'Azul', NULL),
        ( 50, N'Batería portátil 10,000 mAh', N'BAT-POR-NEG',  199.00, NULL, N'Negro', NULL),
        ( 51, N'Batería portátil 10,000 mAh', N'BAT-POR-BLA',  199.00, NULL, N'Blanco', NULL),
        ( 52, N'Mouse inalámbrico ergonómico', N'MOU-INA-NEG',  119.00, NULL, N'Negro', NULL),
        ( 53, N'Mouse inalámbrico ergonómico', N'MOU-INA-GRI',  119.00, NULL, N'Gris', NULL),
        ( 54, N'Teclado mecánico compacto', N'TEC-MEC-NEG',  459.00, NULL, N'Negro', NULL),
        ( 55, N'Cable USB-C a USB-C', N'CAB-USC-1M',   59.00, NULL, NULL, N'1 m'),
        ( 56, N'Cable USB-C a USB-C', N'CAB-USC-2M',   79.00, NULL, NULL, N'2 m'),
        ( 57, N'Reloj inteligente deportivo', N'REL-INT-NEG',  549.00, NULL, N'Negro', NULL),
        ( 58, N'Reloj inteligente deportivo', N'REL-INT-ROS',  549.00, NULL, N'Rosa', NULL),
        ( 59, N'Juego de sábanas de algodón', N'SAB-ALG-MAT-BLA',  289.00, NULL, N'Blanco', N'Matrimonial'),
        ( 60, N'Juego de sábanas de algodón', N'SAB-ALG-QUE-BLA',  339.00, NULL, N'Blanco', N'Queen'),
        ( 61, N'Juego de sábanas de algodón', N'SAB-ALG-MAT-GRI',  289.00, NULL, N'Gris', N'Matrimonial'),
        ( 62, N'Sartén antiadherente', N'SAR-ANT-24',  149.00, NULL, NULL, N'24 cm'),
        ( 63, N'Sartén antiadherente', N'SAR-ANT-28',  189.00, NULL, NULL, N'28 cm'),
        ( 64, N'Juego de toallas de baño', N'TOA-BAN-BLA',  199.00, NULL, N'Blanco', NULL),
        ( 65, N'Juego de toallas de baño', N'TOA-BAN-GRI',  199.00, NULL, N'Gris', NULL),
        ( 66, N'Cafetera de goteo 12 tazas', N'CAF-GOT-12',  279.00, NULL, N'Negro', NULL),
        ( 67, N'Lámpara de escritorio LED', N'LAM-LED-BLA',  169.00, NULL, N'Blanco', NULL),
        ( 68, N'Lámpara de escritorio LED', N'LAM-LED-NEG',  169.00, NULL, N'Negro', NULL),
        ( 69, N'Set de recipientes herméticos', N'REC-HER-10',  139.00, NULL, NULL, N'10 piezas'),
        ( 70, N'Balón de fútbol', N'BAL-FUT-5',  159.00, NULL, NULL, N'Número 5'),
        ( 71, N'Balón de fútbol', N'BAL-FUT-4',  139.00, NULL, NULL, N'Número 4'),
        ( 72, N'Mat de yoga antideslizante', N'MAT-YOG-MOR',  179.00, NULL, N'Morado', NULL),
        ( 73, N'Mat de yoga antideslizante', N'MAT-YOG-AZU',  179.00, NULL, N'Azul', NULL),
        ( 74, N'Botella térmica de acero', N'BOT-TER-NEG',  129.00, NULL, N'Negro', NULL),
        ( 75, N'Botella térmica de acero', N'BOT-TER-BLA',  129.00, NULL, N'Blanco', NULL),
        ( 76, N'Botella térmica de acero', N'BOT-TER-VER',  129.00, NULL, N'Verde', NULL),
        ( 77, N'Par de mancuernas de neopreno', N'MAN-NEO-3LB',   99.00, NULL, NULL, N'3 lb'),
        ( 78, N'Par de mancuernas de neopreno', N'MAN-NEO-5LB',  139.00, NULL, NULL, N'5 lb'),
        ( 79, N'Par de mancuernas de neopreno', N'MAN-NEO-8LB',  199.00, NULL, NULL, N'8 lb'),
        ( 80, N'Cuerda para saltar ajustable', N'CUE-SAL-AJU',   69.00, NULL, N'Negro', NULL),
        ( 81, N'Bloques de construcción 500 piezas', N'BLO-CON-500',  249.00, NULL, NULL, N'500 piezas'),
        ( 82, N'Rompecabezas de Antigua Guatemala', N'ROM-ANT-1000',  129.00, NULL, NULL, N'1,000 piezas'),
        ( 83, N'Carro a control remoto todoterreno', N'CAR-REM-ROJ',  319.00, NULL, N'Rojo', NULL),
        ( 84, N'Carro a control remoto todoterreno', N'CAR-REM-AZU',  319.00, NULL, N'Azul', NULL),
        ( 85, N'Muñeca articulada con accesorios', N'MUN-ART-ACC',  189.00, NULL, NULL, NULL),
        ( 86, N'Juego de mesa de estrategia', N'JUE-MES-EST',  229.00, NULL, NULL, NULL),
        ( 87, N'Protector solar FPS 50', N'PRO-SOL-60',   89.00, NULL, NULL, N'60 ml'),
        ( 88, N'Protector solar FPS 50', N'PRO-SOL-120',  149.00, NULL, NULL, N'120 ml'),
        ( 89, N'Champú con keratina', N'CHA-KER-400',   69.00, NULL, NULL, N'400 ml'),
        ( 90, N'Champú con keratina', N'CHA-KER-750',  109.00, NULL, NULL, N'750 ml'),
        ( 91, N'Crema hidratante facial', N'CRE-HID-50',  129.00, NULL, NULL, N'50 ml'),
        ( 92, N'Kit de brochas de maquillaje', N'KIT-BRO-12',  159.00, NULL, NULL, N'12 piezas'),
        ( 93, N'Perfume floral para dama', N'PER-FLO-50',  289.00, NULL, NULL, N'50 ml'),
        ( 94, N'Perfume floral para dama', N'PER-FLO-100',  429.00, NULL, NULL, N'100 ml'),
        ( 95, N'Bolígrafos de gel 12 colores', N'BOL-GEL-12',   45.00, NULL, NULL, N'12 unidades'),
        ( 96, N'Mochila escolar con compartimento para laptop', N'MOC-ESC-NEG',  259.00, NULL, N'Negro', NULL),
        ( 97, N'Mochila escolar con compartimento para laptop', N'MOC-ESC-AZU',  259.00, NULL, N'Azul', NULL),
        ( 98, N'Calculadora científica', N'CAL-CIE-240',  119.00, NULL, NULL, NULL),
        ( 99, N'Resma de papel bond', N'RES-BON-CAR',   49.00, NULL, NULL, N'Carta'),
        (100, N'Resma de papel bond', N'RES-BON-OFI',   55.00, NULL, NULL, N'Oficio'),
        (101, N'Marcadores fluorescentes', N'MAR-FLU-6',   35.00, NULL, NULL, N'6 unidades');

    INSERT INTO dbo.Variantes (IDProducto, SKU, Precio)
    SELECT p.IDProducto, v.SKU, v.Precio
    FROM @V v
    JOIN dbo.Productos p ON p.Nombre = v.Producto
    ORDER BY v.Orden;

    INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
    SELECT va.IDVariante, a.IDAtributo, x.Valor
    FROM @V v
    JOIN dbo.Variantes va ON va.SKU = v.SKU
    CROSS APPLY (VALUES (N'Talla', v.Talla), (N'Color', v.Color), (N'Presentación', v.Presentacion)) AS x (Atributo, Valor)
    JOIN dbo.Atributos a ON a.Nombre = x.Atributo
    WHERE x.Valor IS NOT NULL;

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
        THROW 50099, N'La conciliación del inventario inicial presenta diferencias.', 1;

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
    (N'BIENVENIDA10', N'10 % de descuento en tu primera compra desde Q100',     N'PORCENTAJE', 10.00, NULL,   100.00,   -1,  90, 100, 1),
    (N'QUETZALES25',  N'Q25 de descuento en compras desde Q250',                 N'MONTO_FIJO', 25.00, NULL,   250.00,   -1,  60, NULL, 3),
    (N'ROPA15',       N'15 % de descuento en toda la categoría Ropa',            N'PORCENTAJE', 15.00, N'Ropa', 0.00,    -1,  45, NULL, 2),
    (N'ULTIMOCUPON',  N'Promoción relámpago: 20 % solo para el primer cliente',  N'PORCENTAJE', 20.00, NULL,    0.00,    -1,  30,    1, 1),
    (N'VENCIDO5',     N'Promoción de fin de mes (finalizada)',                   N'PORCENTAJE',  5.00, NULL,    0.00,   -60, -30, NULL, NULL),
    (N'PROXIMAMENTE', N'Preventa de fin de año: 30 % (disponible próximamente)', N'PORCENTAJE', 30.00, NULL,    0.00,    10,  40, NULL, NULL)
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
    (N'Recoger en tienda', N'Retira tu pedido sin costo en nuestra tienda de zona 10, Ciudad de Guatemala', 0.00, 1),
    (N'Envío estándar',    N'Entrega a domicilio en los 22 departamentos en 3 a 5 días hábiles',           35.00, 4),
    (N'Envío express',     N'Entrega a domicilio al siguiente día hábil',                                   60.00, 1)
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
    DECLARE @DiasHistorial INT = 120, @NumPedidos INT = 3000;
    /* Con 101 variantes, 450 unidades por variante cubren los 3,000 pedidos sin dejar existencias negativas. */
    DECLARE @Reposicion INT = 450;
    DECLARE @Minutos INT = @DiasHistorial * 1440;
    DECLARE @InicioCarga DATETIME2(0) = DATEADD(DAY, -(@DiasHistorial + 6), @Ahora);
    DECLARE @InicioRepo  DATETIME2(0) = DATEADD(DAY, -(@DiasHistorial + 3), @Ahora);
    DECLARE @IDSistema INT = (SELECT IDUsuario FROM dbo.Usuarios WHERE Correo = N'sistema@shopcart.local');
    DECLARE @IDRolCliente INT = (SELECT IDRol FROM dbo.Roles WHERE Nombre = N'Cliente');
    DECLARE @P INT, @TotClientes INT, @TotEnvios INT, @TotDirecciones INT;

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

        /* 1) Clientes de demostración (sin contraseña válida: no pueden iniciar sesión) */
        INSERT INTO dbo.Usuarios (IDRol, Correo, PasswordHash, Nombres, Apellidos, Telefono)
        SELECT  @IDRolCliente, c.Correo, N'!SIN-ACCESO', c.Nombres, c.Apellidos, c.Telefono
        FROM (VALUES
            ( 1, N'María José', N'López García', N'maria.lopez@demo.shopcart.local', N'4919-4729'),
            ( 2, N'José Antonio', N'Pérez Morales', N'jose.perez@demo.shopcart.local', N'5838-9458'),
            ( 3, N'Ana Lucía', N'Hernández Castillo', N'ana.hernandez@demo.shopcart.local', N'3757-4187'),
            ( 4, N'Luis Fernando', N'Ajú Tzul', N'luis.aju@demo.shopcart.local', N'4676-8916'),
            ( 5, N'Carmen Elena', N'Rodríguez Méndez', N'carmen.rodriguez@demo.shopcart.local', N'5595-3645'),
            ( 6, N'Carlos Eduardo', N'Gómez Barrios', N'carlos.gomez@demo.shopcart.local', N'3514-8374'),
            ( 7, N'Sofía Alejandra', N'Ramírez Cifuentes', N'sofia.ramirez@demo.shopcart.local', N'4433-3103'),
            ( 8, N'Diego Alejandro', N'Castillo Orellana', N'diego.castillo@demo.shopcart.local', N'5352-7832'),
            ( 9, N'Lucía Fernanda', N'Morales Quiñónez', N'lucia.morales@demo.shopcart.local', N'3271-2561'),
            (10, N'Miguel Ángel', N'Xicará Coyoy', N'miguel.xicara@demo.shopcart.local', N'4190-7290'),
            (11, N'Andrea Paola', N'Estrada Monzón', N'andrea.estrada@demo.shopcart.local', N'5109-2019'),
            (12, N'Juan Pablo', N'Fuentes Aguilar', N'juan.fuentes@demo.shopcart.local', N'3028-6748'),
            (13, N'Gabriela Isabel', N'Ortiz Velásquez', N'gabriela.ortiz@demo.shopcart.local', N'4947-1477'),
            (14, N'Kevin Estuardo', N'Cabrera Juárez', N'kevin.cabrera@demo.shopcart.local', N'5866-6206'),
            (15, N'Valeria Nicole', N'Samayoa Rivera', N'valeria.samayoa@demo.shopcart.local', N'3785-0935'),
            (16, N'Jorge Mario', N'Mazariegos Oliva', N'jorge.mazariegos@demo.shopcart.local', N'4704-5664'),
            (17, N'Daniela Sofía', N'Pineda Escobar', N'daniela.pineda@demo.shopcart.local', N'5623-0393'),
            (18, N'Erick Rolando', N'Batz Chumil', N'erick.batz@demo.shopcart.local', N'3542-5122'),
            (19, N'Mónica Beatriz', N'Arriaga Solís', N'monica.arriaga@demo.shopcart.local', N'4461-9851'),
            (20, N'Fernando José', N'Herrera Paz', N'fernando.herrera@demo.shopcart.local', N'5380-4580'),
            (21, N'Alejandra María', N'Contreras Lima', N'alejandra.contreras@demo.shopcart.local', N'3299-9309'),
            (22, N'Rodrigo Andrés', N'Villatoro Sandoval', N'rodrigo.villatoro@demo.shopcart.local', N'4218-4038'),
            (23, N'Paola Andrea', N'Recinos Galindo', N'paola.recinos@demo.shopcart.local', N'5137-8767'),
            (24, N'Óscar Daniel', N'Sic Cumes', N'oscar.sic@demo.shopcart.local', N'3056-3496'),
            (25, N'Karla Michelle', N'Figueroa Chávez', N'karla.figueroa@demo.shopcart.local', N'4975-8225'),
            (26, N'Mario Roberto', N'De León Ruiz', N'mario.deleon@demo.shopcart.local', N'5894-2954'),
            (27, N'Ingrid Yesenia', N'Tobar Mejía', N'ingrid.tobar@demo.shopcart.local', N'3813-7683'),
            (28, N'Byron Alexander', N'Gálvez Lemus', N'byron.galvez@demo.shopcart.local', N'4732-2412'),
            (29, N'Claudia Patricia', N'Ralón Marroquín', N'claudia.ralon@demo.shopcart.local', N'5651-7141'),
            (30, N'Eduardo Enrique', N'Arévalo Cordón', N'eduardo.arevalo@demo.shopcart.local', N'3570-1870'),
            (31, N'Wendy Marisol', N'Chacón Godínez', N'wendy.chacon@demo.shopcart.local', N'4489-6599'),
            (32, N'Pablo Javier', N'Alvarado Tejeda', N'pablo.alvarado@demo.shopcart.local', N'5408-1328'),
            (33, N'Rosa María', N'Tzoc Ixcoy', N'rosa.tzoc@demo.shopcart.local', N'3327-6057'),
            (34, N'Héctor Manuel', N'Castañeda Polanco', N'hector.castaneda@demo.shopcart.local', N'4246-0786'),
            (35, N'Lourdes Carolina', N'Barrientos Ovalle', N'lourdes.barrientos@demo.shopcart.local', N'5165-5515'),
            (36, N'Alex Josué', N'Monterroso Duarte', N'alex.monterroso@demo.shopcart.local', N'3084-0244'),
            (37, N'Silvia Lorena', N'Girón Hernández', N'silvia.giron@demo.shopcart.local', N'4003-4973'),
            (38, N'César Augusto', N'Lemus Cardona', N'cesar.lemus@demo.shopcart.local', N'5922-9702'),
            (39, N'Fátima Guadalupe', N'Chávez Son', N'fatima.chavez@demo.shopcart.local', N'3841-4431'),
            (40, N'Javier Alejandro', N'Rosales Cuéllar', N'javier.rosales@demo.shopcart.local', N'4760-9160'),
            (41, N'Natalia Sofía', N'Bran Archila', N'natalia.bran@demo.shopcart.local', N'5679-3889'),
            (42, N'Marco Antonio', N'Urízar Folgar', N'marco.urizar@demo.shopcart.local', N'3598-8618'),
            (43, N'Jennifer Alejandra', N'Salazar Pérez', N'jennifer.salazar@demo.shopcart.local', N'4517-3347'),
            (44, N'Gerson Iván', N'Quemé Chay', N'gerson.queme@demo.shopcart.local', N'5436-8076'),
            (45, N'Ximena Lucía', N'Maldonado Rivas', N'ximena.maldonado@demo.shopcart.local', N'3355-2805'),
            (46, N'Ronald Estuardo', N'Pacheco Gramajo', N'ronald.pacheco@demo.shopcart.local', N'4274-7534'),
            (47, N'Evelyn Johana', N'Santizo Calderón', N'evelyn.santizo@demo.shopcart.local', N'5193-2263'),
            (48, N'Luis Pedro', N'Zelada Arana', N'luis.zelada@demo.shopcart.local', N'3112-6992'),
            (49, N'Melany Alejandra', N'Coyoy Tax', N'melany.coyoy@demo.shopcart.local', N'4031-1721'),
            (50, N'Julio César', N'Ordóñez Lara', N'julio.ordonez@demo.shopcart.local', N'5950-6450'),
            (51, N'Brenda Lisseth', N'Escobar Mus', N'brenda.escobar@demo.shopcart.local', N'3869-1179'),
            (52, N'Sergio David', N'Aldana Bonilla', N'sergio.aldana@demo.shopcart.local', N'4788-5908'),
            (53, N'Astrid Mariela', N'Pérez Tuy', N'astrid.perez@demo.shopcart.local', N'5707-0637'),
            (54, N'Walter Leonel', N'Marroquín Sagastume', N'walter.marroquin@demo.shopcart.local', N'3626-5366'),
            (55, N'Nancy Odilia', N'Vásquez Pirir', N'nancy.vasquez@demo.shopcart.local', N'4545-0095'),
            (56, N'Christian Josué', N'Paiz Del Valle', N'christian.paiz@demo.shopcart.local', N'5464-4824'),
            (57, N'Rocío Alejandra', N'Ayala Linares', N'rocio.ayala@demo.shopcart.local', N'3383-9553'),
            (58, N'Selvin Omar', N'Tum Ajanel', N'selvin.tum@demo.shopcart.local', N'4302-4282'),
            (59, N'Diana Carolina', N'Mendizábal Rosal', N'diana.mendizabal@demo.shopcart.local', N'5221-9011'),
            (60, N'Henry Alexander', N'Cifuentes Godoy', N'henry.cifuentes@demo.shopcart.local', N'3140-3740')
        ) AS c (Ord, Nombres, Apellidos, Correo, Telefono)
        WHERE   NOT EXISTS (SELECT 1 FROM dbo.Usuarios u WHERE u.Correo = c.Correo)
        ORDER BY c.Ord;

        SELECT  ROW_NUMBER() OVER (ORDER BY IDUsuario) AS Ord, IDUsuario, Nombres, Apellidos, Telefono
        INTO    #Clientes
        FROM    dbo.Usuarios
        WHERE   Correo LIKE N'%@demo.shopcart.local';

        /* Direcciones de entrega, asignadas a cada cliente de forma fija */
        CREATE TABLE #Direcciones (Ord INT PRIMARY KEY, Departamento NVARCHAR(100), Municipio NVARCHAR(100), Direccion NVARCHAR(250));
        INSERT INTO #Direcciones (Ord, Departamento, Municipio, Direccion) VALUES
            ( 1, N'Guatemala',      N'Guatemala',          N'6a. avenida 12-45 zona 1'),
            ( 2, N'Guatemala',      N'Guatemala',          N'Boulevard Los Próceres 18-20 zona 10, apartamento 504'),
            ( 3, N'Guatemala',      N'Mixco',              N'Calzada San Juan 32-15 zona 7, colonia Bosques de San Nicolás'),
            ( 4, N'Guatemala',      N'Villa Nueva',        N'Residenciales Villa Linda, manzana C, casa 14, zona 4'),
            ( 5, N'Guatemala',      N'San Miguel Petapa',  N'Calle principal 4-22, colonia Villa Hermosa'),
            ( 6, N'Sacatepéquez',   N'Antigua Guatemala',  N'3a. calle oriente 21'),
            ( 7, N'Quetzaltenango', N'Quetzaltenango',     N'14 avenida 3-08 zona 1'),
            ( 8, N'Quetzaltenango', N'Salcajá',            N'2a. calle 1-45 zona 2'),
            ( 9, N'Escuintla',      N'Escuintla',          N'4a. avenida 6-30 zona 1'),
            (10, N'Alta Verapaz',   N'Cobán',              N'1a. calle 5-12 zona 2'),
            (11, N'Petén',          N'Flores',             N'Calle Centroamérica, casa 15, isla de Flores'),
            (12, N'Huehuetenango',  N'Huehuetenango',      N'5a. avenida 2-56 zona 1'),
            (13, N'Izabal',         N'Puerto Barrios',     N'8a. calle entre 6a. y 7a. avenida'),
            (14, N'Chimaltenango',  N'Chimaltenango',      N'2a. avenida 2-40 zona 3, colonia El Esfuerzo'),
            (15, N'Retalhuleu',     N'Retalhuleu',         N'6a. calle 7-15 zona 1');

        SELECT  ROW_NUMBER() OVER (ORDER BY IDMetodoEnvio) AS Ord, IDMetodoEnvio, Nombre, Costo
        INTO    #Envios
        FROM    dbo.MetodosEnvio
        WHERE   Activo = 1;

        SELECT @TotClientes = COUNT(*) FROM #Clientes;
        SELECT @TotEnvios = COUNT(*) FROM #Envios;
        SELECT @TotDirecciones = COUNT(*) FROM #Direcciones;

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

        /* 2) Reposición previa al periodo de ventas */
        INSERT INTO dbo.MovimientosInventario
            (IDVariante, TipoMovimiento, Cantidad, ExistenciaResultante, Motivo, IDUsuario, Fecha)
        SELECT  e.IDVariante, N'ENTRADA', @Reposicion, v.ExistenciaFisica + @Reposicion,
                N'Reposición de inventario de temporada', @IDSistema, @InicioRepo
        FROM    #Elegibles e
        JOIN    dbo.Variantes v ON v.IDVariante = e.IDVariante
        ORDER BY e.IDVariante;

        UPDATE v
        SET    v.ExistenciaFisica = v.ExistenciaFisica + @Reposicion
        FROM   dbo.Variantes v
        JOIN   #Elegibles e ON e.IDVariante = v.IDVariante;

        SELECT IDVariante, ExistenciaFisica AS Apertura INTO #Apertura FROM dbo.Variantes;

        /* 3) Pedidos */
        SELECT  n.n, c.IDUsuario, c.Nombres, c.Apellidos, c.Telefono,
                ((c.Ord - 1) % @TotDirecciones) + 1 AS OrdDireccion,
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
                p.IDMetodoEnvio, p.NombreEnvio, CONCAT(p.Nombres, N' ', p.Apellidos), p.Telefono,
                d.Departamento, d.Municipio, d.Direccion,
                p.Fecha,
                CASE WHEN DATEADD(MINUTE, ult.Minutos, p.Fecha) > @Ahora THEN @Ahora
                     ELSE DATEADD(MINUTE, ult.Minutos, p.Fecha) END
        FROM    #Ped p
        JOIN    #Tot t ON t.n = p.n
        JOIN    #Direcciones d ON d.Ord = p.OrdDireccion
        CROSS APPLY (SELECT CASE p.Estado
                                WHEN N'PAGADO' THEN 0 WHEN N'EN_PREPARACION' THEN 120 WHEN N'DESPACHADO' THEN 1440
                                WHEN N'ENTREGADO' THEN 4320 WHEN N'CANCELADO' THEN 180 ELSE 7200 END AS Minutos) ult
        ORDER BY p.n;

        SELECT ROW_NUMBER() OVER (ORDER BY IDPedido) AS n, IDPedido INTO #Mapa FROM dbo.Pedidos;

        /* 4) Detalle de los pedidos */
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
                CASE s.Estado
                    WHEN N'PAGADO'           THEN N'Pedido creado con pago aprobado'
                    WHEN N'EN_PREPARACION'   THEN N'Pedido en preparación en bodega'
                    WHEN N'DESPACHADO'       THEN N'Pedido entregado a la empresa de mensajería'
                    WHEN N'ENTREGADO'        THEN N'Pedido recibido por el cliente'
                    WHEN N'CANCELADO'        THEN N'Cancelado a solicitud del cliente'
                    WHEN N'DEVUELTO_PARCIAL' THEN N'Devolución parcial registrada'
                    WHEN N'DEVUELTO'         THEN N'Devolución total registrada'
                END
        FROM    #Ped p
        JOIN    #Mapa m  ON m.n = p.n
        JOIN    @Pasos s ON s.EstadoFinal = p.Estado
        ORDER BY m.IDPedido, s.Orden;

        /* 6) Devoluciones */
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
        SELECT  IDPedido, @IDSistema,
                CHOOSE((Rk % 5) + 1,
                       N'La talla no le quedó al cliente',
                       N'El producto llegó dañado',
                       N'El color es distinto al de la fotografía',
                       N'El cliente cambió de opinión dentro del plazo de devolución',
                       N'Se envió un producto diferente al solicitado'),
                Monto, Fecha
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

        /* 7) Kardex: ventas, cancelaciones y devoluciones */
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
                    CONCAT(N'Cancelación del pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6), N' a solicitud del cliente'), 2
            FROM    #Lineas l
            JOIN    #Ped p  ON p.n = l.n
            JOIN    #Mapa m ON m.n = l.n
            WHERE   p.Estado = N'CANCELADO'
            UNION ALL
            SELECT  l.IDVariante, N'DEVOLUCION',
                    CASE WHEN p.Estado = N'DEVUELTO' THEN l.Cantidad ELSE 1 END,
                    dv.Fecha, N'DEVOLUCION', md.IDDevolucion, @IDSistema,
                    CONCAT(N'Devolución del pedido SC-', RIGHT(CONCAT(N'000000', m.IDPedido), 6), N': producto reingresado a bodega'), 3
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

        /* 8) Carritos abandonados (de clientes y de visitantes) */
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
