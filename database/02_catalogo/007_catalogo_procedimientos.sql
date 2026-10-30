/* =============================================================================
   007_Catalogo_procedimientos.sql
   Módulo 2 - Catálogo: función, stored procedures de categorías, productos,
   variantes, atributos y búsqueda pública. Reejecutable (CREATE OR ALTER).

   Códigos de error personalizados (THROW):
     50040 Categoría no encontrada                              -> 404
     50041 Nombre de categoría duplicado                        -> 409
     50042 Categoría con productos: no se puede eliminar        -> 409
     50050 Producto no encontrado                               -> 404
     50051 Categoría inválida o inactiva                        -> 400
     50052 El producto requiere al menos una variante           -> 400
     50053 Datos de entrada inválidos (JSON o campos)           -> 400
     50054 SKU duplicado                                        -> 409
     50055 Combinación de atributos duplicada en el producto    -> 409
     50056 Atributo inexistente o inactivo                      -> 400
     50057 Variante no encontrada                               -> 404
     50058 Precio inválido (debe ser mayor a cero)              -> 400
     50059 Rango de precios inválido                            -> 400
   (los códigos 50001-50031 están documentados en el script 002)

   Módulos de bitácora usados: Catalogo (categorías), Productos (productos y
   variantes), Precios (cambios de precio).

   Pendiente: SP_Productos_Eliminar (elimina si no hay ventas ni movimientos, y
   si los hay desactiva) se crea después de las tablas de pedidos e inventario.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_ValidarPermiso
    @IDUsuarioActor INT,
    @CodigoPermiso  NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Usuarios u
        JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
        JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
        WHERE u.IDUsuario = @IDUsuarioActor
          AND u.Activo = 1
          AND p.Codigo = @CodigoPermiso
    )
        THROW 50016, N'No tiene permisos para realizar esta acción.', 1;
END;
GO

CREATE OR ALTER FUNCTION dbo.FU_Catalogo_CombinacionesVariantes (@IDProducto INT)
RETURNS TABLE
AS
RETURN (
    SELECT  v.IDVariante,
            ISNULL((SELECT STRING_AGG(CONCAT(a.Nombre, N'=', va.Valor), N'|') WITHIN GROUP (ORDER BY a.Nombre)
                    FROM dbo.VarianteAtributos va
                    JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
                    WHERE va.IDVariante = v.IDVariante), N'') AS Combinacion
    FROM    dbo.Variantes v
    WHERE   v.IDProducto = @IDProducto
);
GO

CREATE OR ALTER PROCEDURE dbo.SP_Atributos_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IDAtributo, Nombre
    FROM   dbo.Atributos
    WHERE  Activo = 1
    ORDER BY Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Categorias_Crear
    @IDUsuarioActor INT,
    @Nombre         NVARCHAR(100),
    @Descripcion    NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    SET @Nombre = LTRIM(RTRIM(@Nombre));
    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    IF @Nombre IS NULL OR @Nombre = N''
        THROW 50053, N'El nombre de la categoría es obligatorio.', 1;

    DECLARE @IDCategoria INT, @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Categorias WITH (UPDLOCK, HOLDLOCK) WHERE Nombre = @Nombre)
            THROW 50041, N'Ya existe una categoría con ese nombre.', 1;

        INSERT INTO dbo.Categorias (Nombre, Descripcion) VALUES (@Nombre, @Descripcion);
        SET @IDCategoria = SCOPE_IDENTITY();

        SET @ValorNuevo = (
            SELECT c.IDCategoria, c.Nombre, c.Descripcion, c.Activo
            FROM dbo.Categorias c WHERE c.IDCategoria = @IDCategoria
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Catalogo', @Entidad = N'Categoria',
            @IDEntidad = @IDCategoria, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCategoria AS IDCategoria;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50041, N'Ya existe una categoría con ese nombre.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Categorias_Actualizar
    @IDUsuarioActor INT,
    @IDCategoria    INT,
    @Nombre         NVARCHAR(100),
    @Descripcion    NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    SET @Nombre = LTRIM(RTRIM(@Nombre));
    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    IF @Nombre IS NULL OR @Nombre = N''
        THROW 50053, N'El nombre de la categoría es obligatorio.', 1;

    DECLARE @NombreActual NVARCHAR(100), @DescripcionActual NVARCHAR(255),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @NombreActual = Nombre, @DescripcionActual = Descripcion
        FROM   dbo.Categorias WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCategoria = @IDCategoria;

        IF @NombreActual IS NULL
            THROW 50040, N'La categoría no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = @Nombre AND IDCategoria <> @IDCategoria)
            THROW 50041, N'Ya existe una categoría con ese nombre.', 1;

        SET @ValorAnterior = (
            SELECT c.IDCategoria, c.Nombre, c.Descripcion FROM dbo.Categorias c
            WHERE c.IDCategoria = @IDCategoria FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Categorias
        SET    Nombre = @Nombre, Descripcion = @Descripcion, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCategoria = @IDCategoria;

        SET @ValorNuevo = (
            SELECT c.IDCategoria, c.Nombre, c.Descripcion FROM dbo.Categorias c
            WHERE c.IDCategoria = @IDCategoria FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Catalogo', @Entidad = N'Categoria',
            @IDEntidad = @IDCategoria, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCategoria AS IDCategoria;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50041, N'Ya existe una categoría con ese nombre.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Categorias_CambiarEstado
    @IDUsuarioActor INT,
    @IDCategoria    INT,
    @Activo         BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    DECLARE @ActivoActual BIT, @Accion NVARCHAR(20),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ActivoActual = Activo
        FROM   dbo.Categorias WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCategoria = @IDCategoria;

        IF @ActivoActual IS NULL
            THROW 50040, N'La categoría no existe.', 1;

        IF @ActivoActual = @Activo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDCategoria AS IDCategoria, @Activo AS Activo;
            RETURN;
        END;

        UPDATE dbo.Categorias
        SET    Activo = @Activo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCategoria = @IDCategoria;

        SET @Accion = CASE WHEN @Activo = 0 THEN N'DESACTIVAR' ELSE N'MODIFICAR' END;
        SET @ValorAnterior = (SELECT @ActivoActual AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Activo       AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Catalogo', @Entidad = N'Categoria',
            @IDEntidad = @IDCategoria, @Accion = @Accion,
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCategoria AS IDCategoria, @Activo AS Activo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Categorias_Eliminar
    @IDUsuarioActor INT,
    @IDCategoria    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    DECLARE @ValorAnterior NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SET @ValorAnterior = (
            SELECT c.IDCategoria, c.Nombre, c.Descripcion, c.Activo
            FROM dbo.Categorias c WITH (UPDLOCK, HOLDLOCK)
            WHERE c.IDCategoria = @IDCategoria
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        IF @ValorAnterior IS NULL
            THROW 50040, N'La categoría no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK) WHERE IDCategoria = @IDCategoria)
            THROW 50042, N'La categoría tiene productos asociados; desactívela en lugar de eliminarla.', 1;

        DELETE FROM dbo.Categorias WHERE IDCategoria = @IDCategoria;

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Catalogo', @Entidad = N'Categoria',
            @IDEntidad = @IDCategoria, @Accion = N'ELIMINAR', @ValorAnterior = @ValorAnterior;

        COMMIT TRANSACTION;

        SELECT @IDCategoria AS IDCategoria;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Categorias_ObtenerPorID
    @IDCategoria INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.IDCategoria, c.Nombre, c.Descripcion, c.Activo, c.FechaCreacion, c.FechaActualizacion
    FROM   dbo.Categorias c
    WHERE  c.IDCategoria = @IDCategoria;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Categorias_Listar
    @Busqueda     NVARCHAR(100) = NULL,
    @Activo       BIT           = NULL,
    @OrdenarPor   NVARCHAR(20)  = N'Nombre',   -- Nombre | FechaCreacion
    @Direccion    NVARCHAR(4)   = N'ASC',      -- ASC | DESC
    @Pagina       INT           = 1,
    @TamanoPagina INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    SELECT  c.IDCategoria, c.Nombre, c.Descripcion, c.Activo, c.FechaCreacion,
            (SELECT COUNT(*) FROM dbo.Productos p WHERE p.IDCategoria = c.IDCategoria) AS TotalProductos,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.Categorias c
    WHERE   (@Activo IS NULL OR c.Activo = @Activo)
        AND (@Busqueda IS NULL
             OR c.Nombre      LIKE N'%' + @Busqueda + N'%'
             OR c.Descripcion LIKE N'%' + @Busqueda + N'%')
    ORDER BY
        CASE WHEN @OrdenarPor = N'Nombre'        AND @Direccion = N'ASC'  THEN c.Nombre        END ASC,
        CASE WHEN @OrdenarPor = N'Nombre'        AND @Direccion = N'DESC' THEN c.Nombre        END DESC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'ASC'  THEN c.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'DESC' THEN c.FechaCreacion END DESC,
        c.IDCategoria
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Productos_Crear
    @IDUsuarioActor INT,
    @IDCategoria    INT,
    @Nombre         NVARCHAR(150),
    @Descripcion    NVARCHAR(MAX) = NULL,
    @Variantes      NVARCHAR(MAX),
    @Imagenes       NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    SET @Nombre = LTRIM(RTRIM(@Nombre));
    IF @Nombre IS NULL OR @Nombre = N''
        THROW 50053, N'El nombre del producto es obligatorio.', 1;
    IF @Variantes IS NULL OR ISJSON(@Variantes) <> 1
        THROW 50053, N'La lista de variantes no es un JSON válido.', 1;
    IF @Imagenes IS NOT NULL AND ISJSON(@Imagenes) <> 1
        THROW 50053, N'La lista de imágenes no es un JSON válido.', 1;

    DECLARE @IDProducto INT, @ValorNuevo NVARCHAR(MAX);

    DECLARE @Var TABLE (
        Orden       INT IDENTITY(1,1) PRIMARY KEY,
        SKU         NVARCHAR(50)  NULL,
        Precio      DECIMAL(12,2) NULL,
        Atributos   NVARCHAR(MAX) NULL,
        Combinacion NVARCHAR(MAX) NULL
    );
    DECLARE @VarAtr TABLE (Orden INT NOT NULL, Atributo NVARCHAR(50) NULL, Valor NVARCHAR(50) NULL);
    DECLARE @Img TABLE (
        Posicion    INT IDENTITY(1,1) PRIMARY KEY,
        Url         NVARCHAR(500) NULL,
        Orden       INT NOT NULL,
        EsPrincipal BIT NOT NULL
    );
    DECLARE @Mapa TABLE (IDVariante INT NOT NULL, SKU NVARCHAR(50) NOT NULL);

    INSERT INTO @Var (SKU, Precio, Atributos)
    SELECT UPPER(LTRIM(RTRIM(j.Sku))), j.Precio, j.Atributos
    FROM OPENJSON(@Variantes) WITH (
            Sku       NVARCHAR(50)  '$.sku',
            Precio    DECIMAL(12,2) '$.precio',
            Atributos NVARCHAR(MAX) '$.atributos' AS JSON
         ) j;

    IF NOT EXISTS (SELECT 1 FROM @Var)
        THROW 50052, N'El producto debe tener al menos una variante.', 1;
    IF EXISTS (SELECT 1 FROM @Var WHERE SKU IS NULL OR SKU = N'' OR CHARINDEX(N' ', SKU) > 0)
        THROW 50053, N'Cada variante requiere un SKU sin espacios.', 1;
    IF EXISTS (SELECT 1 FROM @Var WHERE Precio IS NULL OR Precio <= 0)
        THROW 50058, N'El precio de cada variante debe ser mayor a cero.', 1;
    IF EXISTS (SELECT 1 FROM @Var GROUP BY SKU HAVING COUNT(*) > 1)
        THROW 50054, N'Hay SKU repetidos en la lista de variantes.', 1;

    INSERT INTO @VarAtr (Orden, Atributo, Valor)
    SELECT v.Orden, LTRIM(RTRIM(a.Atributo)), LTRIM(RTRIM(a.Valor))
    FROM @Var v
    CROSS APPLY OPENJSON(ISNULL(v.Atributos, N'[]')) WITH (
            Atributo NVARCHAR(50) '$.atributo',
            Valor    NVARCHAR(50) '$.valor'
         ) a;

    IF EXISTS (SELECT 1 FROM @VarAtr WHERE Atributo IS NULL OR Atributo = N'' OR Valor IS NULL OR Valor = N'')
        THROW 50053, N'Cada atributo requiere nombre y valor.', 1;
    IF EXISTS (SELECT 1 FROM @VarAtr GROUP BY Orden, Atributo HAVING COUNT(*) > 1)
        THROW 50053, N'Un atributo no puede repetirse dentro de la misma variante.', 1;
    IF EXISTS (
        SELECT 1 FROM @VarAtr x
        LEFT JOIN dbo.Atributos a ON a.Nombre = x.Atributo AND a.Activo = 1
        WHERE a.IDAtributo IS NULL
    )
        THROW 50056, N'Alguno de los atributos no existe o está inactivo.', 1;

    UPDATE v
    SET    Combinacion = ISNULL((
               SELECT STRING_AGG(CONCAT(x.Atributo, N'=', x.Valor), N'|') WITHIN GROUP (ORDER BY x.Atributo)
               FROM @VarAtr x WHERE x.Orden = v.Orden), N'')
    FROM   @Var v;

    IF EXISTS (SELECT 1 FROM @Var GROUP BY Combinacion HAVING COUNT(*) > 1)
        THROW 50055, N'Dos variantes tienen la misma combinación de atributos.', 1;

    INSERT INTO @Img (Url, Orden, EsPrincipal)
    SELECT LTRIM(RTRIM(j.Url)), ISNULL(j.Orden, 0), ISNULL(j.EsPrincipal, 0)
    FROM OPENJSON(ISNULL(@Imagenes, N'[]')) WITH (
            Url         NVARCHAR(500) '$.url',
            Orden       INT           '$.orden',
            EsPrincipal BIT           '$.esPrincipal'
         ) j;

    IF EXISTS (SELECT 1 FROM @Img WHERE Url IS NULL OR Url = N''
               OR NOT (Url LIKE N'https://%' OR Url LIKE N'http://%' OR Url LIKE N'/%'))
        THROW 50053, N'Cada imagen requiere una URL http(s) o una ruta relativa.', 1;
    IF (SELECT COUNT(*) FROM @Img WHERE EsPrincipal = 1) > 1
        THROW 50053, N'Solo puede haber una imagen principal.', 1;
    IF EXISTS (SELECT 1 FROM @Img) AND NOT EXISTS (SELECT 1 FROM @Img WHERE EsPrincipal = 1)
        UPDATE @Img SET EsPrincipal = 1 WHERE Posicion = (SELECT MIN(Posicion) FROM @Img);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE IDCategoria = @IDCategoria AND Activo = 1)
            THROW 50051, N'La categoría no existe o está inactiva.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Variantes v JOIN @Var x ON x.SKU = v.SKU)
            THROW 50054, N'Alguno de los SKU ya existe.', 1;

        INSERT INTO dbo.Productos (IDCategoria, Nombre, Descripcion)
        VALUES (@IDCategoria, @Nombre, @Descripcion);
        SET @IDProducto = SCOPE_IDENTITY();

        INSERT INTO dbo.Variantes (IDProducto, SKU, Precio)
        OUTPUT inserted.IDVariante, inserted.SKU INTO @Mapa (IDVariante, SKU)
        SELECT @IDProducto, SKU, Precio FROM @Var ORDER BY Orden;

        INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
        SELECT m.IDVariante, a.IDAtributo, x.Valor
        FROM   @VarAtr x
        JOIN   @Var v ON v.Orden = x.Orden
        JOIN   @Mapa m ON m.SKU = v.SKU
        JOIN   dbo.Atributos a ON a.Nombre = x.Atributo;

        INSERT INTO dbo.ImagenesProducto (IDProducto, Url, Orden, EsPrincipal)
        SELECT @IDProducto, Url, Orden, EsPrincipal FROM @Img ORDER BY Posicion;

        SET @ValorNuevo = (
            SELECT p.IDProducto, p.IDCategoria, p.Nombre, p.Activo,
                   (SELECT v.IDVariante, v.SKU, v.Precio FROM dbo.Variantes v
                    WHERE v.IDProducto = p.IDProducto FOR JSON PATH) AS Variantes
            FROM dbo.Productos p WHERE p.IDProducto = @IDProducto
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Producto',
            @IDEntidad = @IDProducto, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDProducto AS IDProducto;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627) AND ERROR_MESSAGE() LIKE N'%UQ_Variantes_SKU%'
            THROW 50054, N'Alguno de los SKU ya existe.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Productos_Actualizar
    @IDUsuarioActor INT,
    @IDProducto     INT,
    @IDCategoria    INT,
    @Nombre         NVARCHAR(150),
    @Descripcion    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    SET @Nombre = LTRIM(RTRIM(@Nombre));
    IF @Nombre IS NULL OR @Nombre = N''
        THROW 50053, N'El nombre del producto es obligatorio.', 1;

    DECLARE @CategoriaActual INT, @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @CategoriaActual = IDCategoria
        FROM   dbo.Productos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDProducto = @IDProducto;

        IF @CategoriaActual IS NULL
            THROW 50050, N'El producto no existe.', 1;

        IF @IDCategoria <> @CategoriaActual
           AND NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE IDCategoria = @IDCategoria AND Activo = 1)
            THROW 50051, N'La categoría no existe o está inactiva.', 1;

        SET @ValorAnterior = (
            SELECT p.IDProducto, p.IDCategoria, p.Nombre, p.Descripcion FROM dbo.Productos p
            WHERE p.IDProducto = @IDProducto FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Productos
        SET    IDCategoria = @IDCategoria, Nombre = @Nombre, Descripcion = @Descripcion,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDProducto = @IDProducto;

        SET @ValorNuevo = (
            SELECT p.IDProducto, p.IDCategoria, p.Nombre, p.Descripcion FROM dbo.Productos p
            WHERE p.IDProducto = @IDProducto FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Producto',
            @IDEntidad = @IDProducto, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDProducto AS IDProducto;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Productos_CambiarEstado
    @IDUsuarioActor INT,
    @IDProducto     INT,
    @Activo         BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    DECLARE @ActivoActual BIT, @Accion NVARCHAR(20),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ActivoActual = Activo
        FROM   dbo.Productos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDProducto = @IDProducto;

        IF @ActivoActual IS NULL
            THROW 50050, N'El producto no existe.', 1;

        IF @ActivoActual = @Activo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDProducto AS IDProducto, @Activo AS Activo;
            RETURN;
        END;

        UPDATE dbo.Productos
        SET    Activo = @Activo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDProducto = @IDProducto;

        SET @Accion = CASE WHEN @Activo = 0 THEN N'DESACTIVAR' ELSE N'MODIFICAR' END;
        SET @ValorAnterior = (SELECT @ActivoActual AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Activo       AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Producto',
            @IDEntidad = @IDProducto, @Accion = @Accion,
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDProducto AS IDProducto, @Activo AS Activo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Productos_ReemplazarImagenes
    @IDUsuarioActor INT,
    @IDProducto     INT,
    @Imagenes       NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    IF @Imagenes IS NULL OR ISJSON(@Imagenes) <> 1
        THROW 50053, N'La lista de imágenes no es un JSON válido.', 1;

    DECLARE @Existe INT, @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);
    DECLARE @Img TABLE (
        Posicion    INT IDENTITY(1,1) PRIMARY KEY,
        Url         NVARCHAR(500) NULL,
        Orden       INT NOT NULL,
        EsPrincipal BIT NOT NULL
    );

    INSERT INTO @Img (Url, Orden, EsPrincipal)
    SELECT LTRIM(RTRIM(j.Url)), ISNULL(j.Orden, 0), ISNULL(j.EsPrincipal, 0)
    FROM OPENJSON(@Imagenes) WITH (
            Url         NVARCHAR(500) '$.url',
            Orden       INT           '$.orden',
            EsPrincipal BIT           '$.esPrincipal'
         ) j;

    IF EXISTS (SELECT 1 FROM @Img WHERE Url IS NULL OR Url = N''
               OR NOT (Url LIKE N'https://%' OR Url LIKE N'http://%' OR Url LIKE N'/%'))
        THROW 50053, N'Cada imagen requiere una URL http(s) o una ruta relativa.', 1;
    IF (SELECT COUNT(*) FROM @Img WHERE EsPrincipal = 1) > 1
        THROW 50053, N'Solo puede haber una imagen principal.', 1;
    IF EXISTS (SELECT 1 FROM @Img) AND NOT EXISTS (SELECT 1 FROM @Img WHERE EsPrincipal = 1)
        UPDATE @Img SET EsPrincipal = 1 WHERE Posicion = (SELECT MIN(Posicion) FROM @Img);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Existe = IDProducto FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK) WHERE IDProducto = @IDProducto;
        IF @Existe IS NULL
            THROW 50050, N'El producto no existe.', 1;

        SET @ValorAnterior = (
            SELECT (SELECT i.Url, i.Orden, i.EsPrincipal FROM dbo.ImagenesProducto i
                    WHERE i.IDProducto = @IDProducto ORDER BY i.Orden FOR JSON PATH) AS Imagenes
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        DELETE FROM dbo.ImagenesProducto WHERE IDProducto = @IDProducto;

        INSERT INTO dbo.ImagenesProducto (IDProducto, Url, Orden, EsPrincipal)
        SELECT @IDProducto, Url, Orden, EsPrincipal FROM @Img ORDER BY Posicion;

        SET @ValorNuevo = (
            SELECT (SELECT i.Url, i.Orden, i.EsPrincipal FROM dbo.ImagenesProducto i
                    WHERE i.IDProducto = @IDProducto ORDER BY i.Orden FOR JSON PATH) AS Imagenes
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Producto',
            @IDEntidad = @IDProducto, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDProducto AS IDProducto;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Productos_ObtenerDetalle
    @IDProducto     INT,
    @IDUsuarioActor INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VerTodo BIT = 0, @IDVisible INT;

    IF @IDUsuarioActor IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM dbo.Usuarios u
            JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
            JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
            WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1 AND p.Codigo = N'CATALOGO_GESTIONAR')
        SET @VerTodo = 1;

    SELECT @IDVisible = p.IDProducto
    FROM   dbo.Productos p
    JOIN   dbo.Categorias c ON c.IDCategoria = p.IDCategoria
    WHERE  p.IDProducto = @IDProducto
      AND  (@VerTodo = 1 OR (p.Activo = 1 AND c.Activo = 1));

    SELECT p.IDProducto, p.Nombre, p.Descripcion, p.Activo, p.IDCategoria, c.Nombre AS Categoria,
           p.FechaCreacion, p.FechaActualizacion
    FROM   dbo.Productos p
    JOIN   dbo.Categorias c ON c.IDCategoria = p.IDCategoria
    WHERE  p.IDProducto = @IDVisible;

    SELECT i.IDImagenProducto, i.Url, i.Orden, i.EsPrincipal
    FROM   dbo.ImagenesProducto i
    WHERE  i.IDProducto = @IDVisible
    ORDER BY i.Orden, i.IDImagenProducto;

    SELECT v.IDVariante, v.SKU, v.Precio, v.ExistenciaDisponible, v.Activo,
           CASE WHEN @VerTodo = 1 THEN v.ExistenciaFisica    END AS ExistenciaFisica,
           CASE WHEN @VerTodo = 1 THEN v.ExistenciaReservada END AS ExistenciaReservada
    FROM   dbo.Variantes v
    WHERE  v.IDProducto = @IDVisible
      AND  (@VerTodo = 1 OR v.Activo = 1)
    ORDER BY v.IDVariante;

    SELECT va.IDVariante, a.Nombre AS Atributo, va.Valor
    FROM   dbo.VarianteAtributos va
    JOIN   dbo.Atributos a ON a.IDAtributo = va.IDAtributo
    JOIN   dbo.Variantes v ON v.IDVariante = va.IDVariante
    WHERE  v.IDProducto = @IDVisible
      AND  (@VerTodo = 1 OR v.Activo = 1)
    ORDER BY va.IDVariante, a.Nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Variantes_Crear
    @IDUsuarioActor INT,
    @IDProducto     INT,
    @SKU            NVARCHAR(50),
    @Precio         DECIMAL(12,2),
    @Atributos      NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    SET @SKU = UPPER(LTRIM(RTRIM(@SKU)));
    IF @SKU IS NULL OR @SKU = N'' OR CHARINDEX(N' ', @SKU) > 0
        THROW 50053, N'El SKU es obligatorio y no puede contener espacios.', 1;
    IF @Precio IS NULL OR @Precio <= 0
        THROW 50058, N'El precio debe ser mayor a cero.', 1;
    IF @Atributos IS NOT NULL AND ISJSON(@Atributos) <> 1
        THROW 50053, N'La lista de atributos no es un JSON válido.', 1;

    DECLARE @IDVariante INT, @Combinacion NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX), @Existe INT;
    DECLARE @Atr TABLE (Atributo NVARCHAR(50) NULL, Valor NVARCHAR(50) NULL);

    INSERT INTO @Atr (Atributo, Valor)
    SELECT LTRIM(RTRIM(j.Atributo)), LTRIM(RTRIM(j.Valor))
    FROM OPENJSON(ISNULL(@Atributos, N'[]')) WITH (
            Atributo NVARCHAR(50) '$.atributo',
            Valor    NVARCHAR(50) '$.valor'
         ) j;

    IF EXISTS (SELECT 1 FROM @Atr WHERE Atributo IS NULL OR Atributo = N'' OR Valor IS NULL OR Valor = N'')
        THROW 50053, N'Cada atributo requiere nombre y valor.', 1;
    IF EXISTS (SELECT 1 FROM @Atr GROUP BY Atributo HAVING COUNT(*) > 1)
        THROW 50053, N'Un atributo no puede repetirse dentro de la misma variante.', 1;
    IF EXISTS (
        SELECT 1 FROM @Atr x
        LEFT JOIN dbo.Atributos a ON a.Nombre = x.Atributo AND a.Activo = 1
        WHERE a.IDAtributo IS NULL
    )
        THROW 50056, N'Alguno de los atributos no existe o está inactivo.', 1;

    SELECT @Combinacion = ISNULL(STRING_AGG(CONCAT(Atributo, N'=', Valor), N'|') WITHIN GROUP (ORDER BY Atributo), N'')
    FROM   @Atr;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Existe = IDProducto FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK) WHERE IDProducto = @IDProducto;
        IF @Existe IS NULL
            THROW 50050, N'El producto no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Variantes WHERE SKU = @SKU)
            THROW 50054, N'El SKU ya existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.FU_Catalogo_CombinacionesVariantes(@IDProducto) WHERE Combinacion = @Combinacion)
            THROW 50055, N'Ya existe una variante con esa combinación de atributos.', 1;

        INSERT INTO dbo.Variantes (IDProducto, SKU, Precio) VALUES (@IDProducto, @SKU, @Precio);
        SET @IDVariante = SCOPE_IDENTITY();

        INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
        SELECT @IDVariante, a.IDAtributo, x.Valor
        FROM   @Atr x
        JOIN   dbo.Atributos a ON a.Nombre = x.Atributo;

        SET @ValorNuevo = (
            SELECT v.IDVariante, v.IDProducto, v.SKU, v.Precio, v.Activo,
                   (SELECT x.Atributo, x.Valor FROM @Atr x FOR JSON PATH) AS Atributos
            FROM dbo.Variantes v WHERE v.IDVariante = @IDVariante
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Variante',
            @IDEntidad = @IDVariante, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDVariante AS IDVariante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627) AND ERROR_MESSAGE() LIKE N'%UQ_Variantes_SKU%'
            THROW 50054, N'El SKU ya existe.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Variantes_Actualizar
    @IDUsuarioActor INT,
    @IDVariante     INT,
    @SKU            NVARCHAR(50),
    @Atributos      NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    SET @SKU = UPPER(LTRIM(RTRIM(@SKU)));
    IF @SKU IS NULL OR @SKU = N'' OR CHARINDEX(N' ', @SKU) > 0
        THROW 50053, N'El SKU es obligatorio y no puede contener espacios.', 1;
    IF @Atributos IS NOT NULL AND ISJSON(@Atributos) <> 1
        THROW 50053, N'La lista de atributos no es un JSON válido.', 1;

    DECLARE @IDProducto INT, @Combinacion NVARCHAR(MAX), @Existe INT, @SKUActual NVARCHAR(50),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);
    DECLARE @Atr TABLE (Atributo NVARCHAR(50) NULL, Valor NVARCHAR(50) NULL);

    IF @Atributos IS NOT NULL
    BEGIN
        INSERT INTO @Atr (Atributo, Valor)
        SELECT LTRIM(RTRIM(j.Atributo)), LTRIM(RTRIM(j.Valor))
        FROM OPENJSON(@Atributos) WITH (
                Atributo NVARCHAR(50) '$.atributo',
                Valor    NVARCHAR(50) '$.valor'
             ) j;

        IF EXISTS (SELECT 1 FROM @Atr WHERE Atributo IS NULL OR Atributo = N'' OR Valor IS NULL OR Valor = N'')
            THROW 50053, N'Cada atributo requiere nombre y valor.', 1;
        IF EXISTS (SELECT 1 FROM @Atr GROUP BY Atributo HAVING COUNT(*) > 1)
            THROW 50053, N'Un atributo no puede repetirse dentro de la misma variante.', 1;
        IF EXISTS (
            SELECT 1 FROM @Atr x
            LEFT JOIN dbo.Atributos a ON a.Nombre = x.Atributo AND a.Activo = 1
            WHERE a.IDAtributo IS NULL
        )
            THROW 50056, N'Alguno de los atributos no existe o está inactivo.', 1;

        SELECT @Combinacion = ISNULL(STRING_AGG(CONCAT(Atributo, N'=', Valor), N'|') WITHIN GROUP (ORDER BY Atributo), N'')
        FROM   @Atr;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IDProducto = IDProducto FROM dbo.Variantes WHERE IDVariante = @IDVariante;
        IF @IDProducto IS NULL
            THROW 50057, N'La variante no existe.', 1;

        SELECT @Existe = IDProducto FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK) WHERE IDProducto = @IDProducto;
        SELECT @SKUActual = SKU FROM dbo.Variantes WITH (UPDLOCK) WHERE IDVariante = @IDVariante;
        IF @SKUActual IS NULL
            THROW 50057, N'La variante no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Variantes WHERE SKU = @SKU AND IDVariante <> @IDVariante)
            THROW 50054, N'El SKU ya existe.', 1;

        IF @Atributos IS NOT NULL
           AND EXISTS (SELECT 1 FROM dbo.FU_Catalogo_CombinacionesVariantes(@IDProducto)
                       WHERE Combinacion = @Combinacion AND IDVariante <> @IDVariante)
            THROW 50055, N'Ya existe una variante con esa combinación de atributos.', 1;

        SET @ValorAnterior = (
            SELECT v.IDVariante, v.SKU,
                   (SELECT a.Nombre AS Atributo, va.Valor
                    FROM dbo.VarianteAtributos va JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
                    WHERE va.IDVariante = v.IDVariante FOR JSON PATH) AS Atributos
            FROM dbo.Variantes v WHERE v.IDVariante = @IDVariante
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Variantes
        SET    SKU = @SKU, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDVariante = @IDVariante;

        IF @Atributos IS NOT NULL
        BEGIN
            DELETE FROM dbo.VarianteAtributos WHERE IDVariante = @IDVariante;

            INSERT INTO dbo.VarianteAtributos (IDVariante, IDAtributo, Valor)
            SELECT @IDVariante, a.IDAtributo, x.Valor
            FROM   @Atr x
            JOIN   dbo.Atributos a ON a.Nombre = x.Atributo;
        END;

        SET @ValorNuevo = (
            SELECT v.IDVariante, v.SKU,
                   (SELECT a.Nombre AS Atributo, va.Valor
                    FROM dbo.VarianteAtributos va JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
                    WHERE va.IDVariante = v.IDVariante FOR JSON PATH) AS Atributos
            FROM dbo.Variantes v WHERE v.IDVariante = @IDVariante
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Variante',
            @IDEntidad = @IDVariante, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDVariante AS IDVariante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627) AND ERROR_MESSAGE() LIKE N'%UQ_Variantes_SKU%'
            THROW 50054, N'El SKU ya existe.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Variantes_CambiarEstado
    @IDUsuarioActor INT,
    @IDVariante     INT,
    @Activo         BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';

    DECLARE @ActivoActual BIT, @Accion NVARCHAR(20),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ActivoActual = Activo
        FROM   dbo.Variantes WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDVariante = @IDVariante;

        IF @ActivoActual IS NULL
            THROW 50057, N'La variante no existe.', 1;

        IF @ActivoActual = @Activo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDVariante AS IDVariante, @Activo AS Activo;
            RETURN;
        END;

        UPDATE dbo.Variantes
        SET    Activo = @Activo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDVariante = @IDVariante;

        SET @Accion = CASE WHEN @Activo = 0 THEN N'DESACTIVAR' ELSE N'MODIFICAR' END;
        SET @ValorAnterior = (SELECT @ActivoActual AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Activo       AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Variante',
            @IDEntidad = @IDVariante, @Accion = @Accion,
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDVariante AS IDVariante, @Activo AS Activo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Variantes_CambiarPrecio
    @IDUsuarioActor INT,
    @IDVariante     INT,
    @PrecioNuevo    DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'PRECIOS_GESTIONAR';

    IF @PrecioNuevo IS NULL OR @PrecioNuevo <= 0
        THROW 50058, N'El precio debe ser mayor a cero.', 1;

    DECLARE @PrecioActual DECIMAL(12,2), @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @PrecioActual = Precio
        FROM   dbo.Variantes WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDVariante = @IDVariante;

        IF @PrecioActual IS NULL
            THROW 50057, N'La variante no existe.', 1;

        IF @PrecioActual = @PrecioNuevo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDVariante AS IDVariante, @PrecioNuevo AS Precio;
            RETURN;
        END;

        UPDATE dbo.Variantes
        SET    Precio = @PrecioNuevo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDVariante = @IDVariante;

        SET @ValorAnterior = (SELECT @PrecioActual AS Precio FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @PrecioNuevo  AS Precio FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Precios', @Entidad = N'Variante',
            @IDEntidad = @IDVariante, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDVariante AS IDVariante, @PrecioNuevo AS Precio;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Catalogo_Buscar
    @IDUsuarioActor  INT           = NULL,
    @Texto           NVARCHAR(100) = NULL,
    @IDCategoria     INT           = NULL,
    @PrecioMin       DECIMAL(12,2) = NULL,
    @PrecioMax       DECIMAL(12,2) = NULL,
    @SoloDisponibles BIT           = 0,
    @Activo          BIT           = NULL,
    @OrdenarPor      NVARCHAR(20)  = N'Nombre',   -- Nombre | Precio | FechaCreacion
    @Direccion       NVARCHAR(4)   = N'ASC',      -- ASC | DESC
    @Pagina          INT           = 1,
    @TamanoPagina    INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @VerTodo BIT = 0;

    IF @IDUsuarioActor IS NOT NULL
       AND EXISTS (
            SELECT 1
            FROM dbo.Usuarios u
            JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
            JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
            WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1 AND p.Codigo = N'CATALOGO_GESTIONAR')
        SET @VerTodo = 1;

    IF @PrecioMin IS NOT NULL AND @PrecioMax IS NOT NULL AND @PrecioMin > @PrecioMax
        THROW 50059, N'El precio mínimo no puede ser mayor al máximo.', 1;

    IF @VerTodo = 0 SET @Activo = 1;
    SET @SoloDisponibles = ISNULL(@SoloDisponibles, 0);
    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    DECLARE @Patron NVARCHAR(102) =
        CASE WHEN @Texto IS NULL OR LTRIM(RTRIM(@Texto)) = N'' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Texto)) + N'%' END;

    ;WITH Resumen AS (
        SELECT  p.IDProducto, p.Nombre, p.Activo, p.IDCategoria, c.Nombre AS Categoria, p.FechaCreacion,
                MIN(v.Precio) AS PrecioDesde,
                MAX(v.Precio) AS PrecioHasta,
                SUM(v.ExistenciaDisponible) AS Disponible,
                COUNT(*) AS TotalVariantes
        FROM    dbo.Productos p
        JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        JOIN    dbo.Variantes v  ON v.IDProducto = p.IDProducto
        WHERE   (@VerTodo = 1 OR (c.Activo = 1 AND v.Activo = 1))
            AND (@Activo IS NULL OR p.Activo = @Activo)
            AND (@IDCategoria IS NULL OR p.IDCategoria = @IDCategoria)
            AND (@PrecioMin IS NULL OR v.Precio >= @PrecioMin)
            AND (@PrecioMax IS NULL OR v.Precio <= @PrecioMax)
            AND (@SoloDisponibles = 0 OR v.ExistenciaDisponible > 0)
            AND (@Patron IS NULL
                 OR p.Nombre LIKE @Patron
                 OR p.Descripcion LIKE @Patron
                 OR EXISTS (SELECT 1 FROM dbo.Variantes vs
                            WHERE vs.IDProducto = p.IDProducto AND vs.SKU LIKE @Patron))
        GROUP BY p.IDProducto, p.Nombre, p.Activo, p.IDCategoria, c.Nombre, p.FechaCreacion
    )
    SELECT  r.IDProducto, r.Nombre, r.Activo, r.IDCategoria, r.Categoria, r.FechaCreacion,
            r.PrecioDesde, r.PrecioHasta, r.Disponible, r.TotalVariantes,
            i.Url AS ImagenPrincipal,
            COUNT(*) OVER () AS TotalRegistros
    FROM    Resumen r
    LEFT JOIN dbo.ImagenesProducto i ON i.IDProducto = r.IDProducto AND i.EsPrincipal = 1
    ORDER BY
        CASE WHEN @OrdenarPor = N'Nombre'        AND @Direccion = N'ASC'  THEN r.Nombre        END ASC,
        CASE WHEN @OrdenarPor = N'Nombre'        AND @Direccion = N'DESC' THEN r.Nombre        END DESC,
        CASE WHEN @OrdenarPor = N'Precio'        AND @Direccion = N'ASC'  THEN r.PrecioDesde   END ASC,
        CASE WHEN @OrdenarPor = N'Precio'        AND @Direccion = N'DESC' THEN r.PrecioDesde   END DESC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'ASC'  THEN r.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'DESC' THEN r.FechaCreacion END DESC,
        r.IDProducto
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'009_Catalogo_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'009_Catalogo_Procedimientos.sql');
GO

CREATE OR ALTER PROCEDURE dbo.SP_Productos_Eliminar
    @IDUsuarioActor INT,
    @IDProducto     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';
 
    DECLARE @Activo BIT, @TieneHistorial BIT = 0, @Resultado NVARCHAR(12),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        SELECT @Activo = Activo
        FROM   dbo.Productos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDProducto = @IDProducto;
 
        IF @Activo IS NULL
            THROW 50050, N'El producto no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM dbo.DetallePedidos d
                   JOIN dbo.Variantes v ON v.IDVariante = d.IDVariante WHERE v.IDProducto = @IDProducto)
           OR EXISTS (SELECT 1 FROM dbo.MovimientosInventario m
                   JOIN dbo.Variantes v ON v.IDVariante = m.IDVariante WHERE v.IDProducto = @IDProducto)
           OR EXISTS (SELECT 1 FROM dbo.ReservasDetalle r
                   JOIN dbo.Variantes v ON v.IDVariante = r.IDVariante WHERE v.IDProducto = @IDProducto)
            SET @TieneHistorial = 1;
 
        IF @TieneHistorial = 1
        BEGIN
            SET @Resultado = N'DESACTIVADO';
 
            IF @Activo = 1
            BEGIN
                UPDATE dbo.Productos
                SET    Activo = 0, FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDProducto = @IDProducto;
 
                SET @ValorAnterior = (SELECT CAST(1 AS BIT) AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
                SET @ValorNuevo    = (SELECT CAST(0 AS BIT) AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
 
                EXEC dbo.SP_Bitacora_Registrar
                    @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Producto',
                    @IDEntidad = @IDProducto, @Accion = N'DESACTIVAR',
                    @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;
            END;
        END
        ELSE
        BEGIN
            SET @Resultado = N'ELIMINADO';
 
            SET @ValorAnterior = (
                SELECT p.IDProducto, p.IDCategoria, p.Nombre, p.Activo,
                       (SELECT v.IDVariante, v.SKU, v.Precio FROM dbo.Variantes v
                        WHERE v.IDProducto = p.IDProducto FOR JSON PATH) AS Variantes
                FROM dbo.Productos p WHERE p.IDProducto = @IDProducto
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            );
 
            DELETE cd FROM dbo.CarritosDetalle cd
            JOIN dbo.Variantes v ON v.IDVariante = cd.IDVariante WHERE v.IDProducto = @IDProducto;
 
            DELETE va FROM dbo.VarianteAtributos va
            JOIN dbo.Variantes v ON v.IDVariante = va.IDVariante WHERE v.IDProducto = @IDProducto;
 
            DELETE FROM dbo.Variantes        WHERE IDProducto = @IDProducto;
            DELETE FROM dbo.ImagenesProducto WHERE IDProducto = @IDProducto;
            DELETE FROM dbo.Productos        WHERE IDProducto = @IDProducto;
 
            EXEC dbo.SP_Bitacora_Registrar
                @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Producto',
                @IDEntidad = @IDProducto, @Accion = N'ELIMINAR', @ValorAnterior = @ValorAnterior;
        END;
 
        COMMIT TRANSACTION;
 
        SELECT @IDProducto AS IDProducto, @Resultado AS Resultado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
 
CREATE OR ALTER PROCEDURE dbo.SP_Variantes_Eliminar
    @IDUsuarioActor INT,
    @IDVariante     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CATALOGO_GESTIONAR';
 
    DECLARE @IDProducto INT, @Existe INT, @Activo BIT, @TieneHistorial BIT = 0, @Resultado NVARCHAR(12),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        SELECT @IDProducto = IDProducto FROM dbo.Variantes WHERE IDVariante = @IDVariante;
        IF @IDProducto IS NULL
            THROW 50057, N'La variante no existe.', 1;
 
        SELECT @Existe = IDProducto FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK) WHERE IDProducto = @IDProducto;
        SELECT @Activo = Activo FROM dbo.Variantes WITH (UPDLOCK, HOLDLOCK) WHERE IDVariante = @IDVariante;
        IF @Activo IS NULL
            THROW 50057, N'La variante no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM dbo.DetallePedidos    WHERE IDVariante = @IDVariante)
           OR EXISTS (SELECT 1 FROM dbo.MovimientosInventario WHERE IDVariante = @IDVariante)
           OR EXISTS (SELECT 1 FROM dbo.ReservasDetalle WHERE IDVariante = @IDVariante)
            SET @TieneHistorial = 1;
 
        IF @TieneHistorial = 1
        BEGIN
            SET @Resultado = N'DESACTIVADO';
 
            IF @Activo = 1
            BEGIN
                UPDATE dbo.Variantes
                SET    Activo = 0, FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDVariante = @IDVariante;
 
                SET @ValorAnterior = (SELECT CAST(1 AS BIT) AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
                SET @ValorNuevo    = (SELECT CAST(0 AS BIT) AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
 
                EXEC dbo.SP_Bitacora_Registrar
                    @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Variante',
                    @IDEntidad = @IDVariante, @Accion = N'DESACTIVAR',
                    @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;
            END;
        END
        ELSE
        BEGIN
            IF (SELECT COUNT(*) FROM dbo.Variantes WHERE IDProducto = @IDProducto) <= 1
                THROW 50052, N'El producto debe tener al menos una variante.', 1;
 
            SET @Resultado = N'ELIMINADO';
 
            SET @ValorAnterior = (
                SELECT v.IDVariante, v.IDProducto, v.SKU, v.Precio, v.Activo
                FROM dbo.Variantes v WHERE v.IDVariante = @IDVariante
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            );
 
            DELETE FROM dbo.CarritosDetalle   WHERE IDVariante = @IDVariante;
            DELETE FROM dbo.VarianteAtributos WHERE IDVariante = @IDVariante;
            DELETE FROM dbo.Variantes         WHERE IDVariante = @IDVariante;
 
            EXEC dbo.SP_Bitacora_Registrar
                @IDUsuario = @IDUsuarioActor, @Modulo = N'Productos', @Entidad = N'Variante',
                @IDEntidad = @IDVariante, @Accion = N'ELIMINAR', @ValorAnterior = @ValorAnterior;
        END;
 
        COMMIT TRANSACTION;
 
        SELECT @IDVariante AS IDVariante, @Resultado AS Resultado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO