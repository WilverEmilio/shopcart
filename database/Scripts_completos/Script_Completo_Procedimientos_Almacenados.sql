USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Bitacora_Registrar
    @IDUsuario     INT           = NULL,
    @Modulo        NVARCHAR(50),
    @Entidad       NVARCHAR(50),
    @IDEntidad     BIGINT        = NULL,
    @Accion        NVARCHAR(20),
    @ValorAnterior NVARCHAR(MAX) = NULL,
    @ValorNuevo    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Bitacora (IDUsuario, Modulo, Entidad, IDEntidad, Accion, ValorAnterior, ValorNuevo)
    VALUES (@IDUsuario, @Modulo, @Entidad, @IDEntidad, @Accion, @ValorAnterior, @ValorNuevo);
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_Verificar_Activo
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Activo
    FROM dbo.Usuarios
    WHERE IDUsuario = @IDUsuario;
END;
GO


/*autenticaci�n*/
CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_ValidarAdministrador
    @IDUsuarioActor INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Usuarios u
        JOIN dbo.Roles r ON r.IDRol = u.IDRol
        WHERE u.IDUsuario = @IDUsuarioActor
          AND u.Activo = 1
          AND r.Nombre = N'Administrador'
    )
        THROW 50016, N'No tiene permisos para realizar esta acci�n.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Bitacora_Listar
    @IDUsuarioActor INT,
    @Modulo         NVARCHAR(50) = NULL,
    @IDUsuario      INT          = NULL,
    @FechaDesde     DATETIME2(0) = NULL,
    @FechaHasta     DATETIME2(0) = NULL,
    @Pagina         INT          = 1,
    @TamanoPagina   INT          = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarAdministrador @IDUsuarioActor = @IDUsuarioActor;

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    SELECT  b.IDBitacora,
            b.Fecha,
            b.Modulo,
            b.Entidad,
            b.IDEntidad,
            b.Accion,
            b.ValorAnterior,
            b.ValorNuevo,
            b.IDUsuario,
            u.Correo AS CorreoUsuario,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.Bitacora b
    LEFT JOIN dbo.Usuarios u ON u.IDUsuario = b.IDUsuario
    WHERE   (@Modulo     IS NULL OR b.Modulo    = @Modulo)
        AND (@IDUsuario  IS NULL OR b.IDUsuario = @IDUsuario)
        AND (@FechaDesde IS NULL OR b.Fecha    >= @FechaDesde)
        AND (@FechaHasta IS NULL OR b.Fecha    <= @FechaHasta)
    ORDER BY b.Fecha DESC, b.IDBitacora DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_RegistrarCliente
    @Correo       NVARCHAR(255),
    @PasswordHash NVARCHAR(255),
    @Nombres      NVARCHAR(100),
    @Apellidos    NVARCHAR(100),
    @Telefono     NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IDRol INT, @IDUsuario INT, @ValorNuevo NVARCHAR(MAX);

    SELECT @IDRol = IDRol FROM dbo.Roles WHERE Nombre = N'Cliente' AND Activo = 1;
    IF @IDRol IS NULL
        THROW 50001, N'El rol Cliente no est� configurado.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Usuarios WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo)
            THROW 50010, N'El correo ya est� registrado.', 1;

        INSERT INTO dbo.Usuarios (IDRol, Correo, PasswordHash, Nombres, Apellidos, Telefono)
        VALUES (@IDRol, @Correo, @PasswordHash, @Nombres, @Apellidos, @Telefono);

        SET @IDUsuario = SCOPE_IDENTITY();

        SET @ValorNuevo = (
            SELECT @IDUsuario AS IDUsuario, @Correo AS Correo, @Nombres AS Nombres,
                   @Apellidos AS Apellidos, @Telefono AS Telefono, @IDRol AS IDRol,
                   CAST(1 AS BIT) AS Activo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuario, @Modulo = N'Usuarios', @Entidad = N'Usuario',
            @IDEntidad = @IDUsuario, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDUsuario AS IDUsuario;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50010, N'El correo ya est� registrado.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_CrearUsuarioInterno
    @IDUsuarioActor INT,
    @Correo         NVARCHAR(255),
    @PasswordHash   NVARCHAR(255),
    @Nombres        NVARCHAR(100),
    @Apellidos      NVARCHAR(100),
    @Telefono       NVARCHAR(20) = NULL,
    @NombreRol      NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarAdministrador @IDUsuarioActor = @IDUsuarioActor;

    DECLARE @IDRol INT, @IDUsuario INT, @ValorNuevo NVARCHAR(MAX);

    IF @NombreRol NOT IN (N'Operador', N'Administrador')
        THROW 50011, N'Solo se pueden crear usuarios internos con rol Operador o Administrador.', 1;

    SELECT @IDRol = IDRol FROM dbo.Roles WHERE Nombre = @NombreRol AND Activo = 1;
    IF @IDRol IS NULL
        THROW 50001, N'El rol solicitado no est� configurado.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Usuarios WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo)
            THROW 50010, N'El correo ya est� registrado.', 1;

        INSERT INTO dbo.Usuarios (IDRol, Correo, PasswordHash, Nombres, Apellidos, Telefono)
        VALUES (@IDRol, @Correo, @PasswordHash, @Nombres, @Apellidos, @Telefono);

        SET @IDUsuario = SCOPE_IDENTITY();

        SET @ValorNuevo = (
            SELECT @IDUsuario AS IDUsuario, @Correo AS Correo, @Nombres AS Nombres,
                   @Apellidos AS Apellidos, @Telefono AS Telefono, @IDRol AS IDRol,
                   CAST(1 AS BIT) AS Activo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Usuarios', @Entidad = N'Usuario',
            @IDEntidad = @IDUsuario, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDUsuario AS IDUsuario;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50010, N'El correo ya est� registrado.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_ObtenerPorCorreo
    @Correo NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  u.IDUsuario, u.Correo, u.PasswordHash, u.Nombres, u.Apellidos, u.Activo,
            r.IDRol, r.Nombre AS Rol
    FROM    dbo.Usuarios u
    JOIN    dbo.Roles r ON r.IDRol = u.IDRol
    WHERE   u.Correo = @Correo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_ObtenerPorID
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  u.IDUsuario, u.Correo, u.Nombres, u.Apellidos, u.Telefono, u.Activo,
            u.FechaCreacion, r.IDRol, r.Nombre AS Rol
    FROM    dbo.Usuarios u
    JOIN    dbo.Roles r ON r.IDRol = u.IDRol
    WHERE   u.IDUsuario = @IDUsuario;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_ObtenerPermisos
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  p.Codigo
    FROM    dbo.Usuarios u
    JOIN    dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
    JOIN    dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
    WHERE   u.IDUsuario = @IDUsuario
        AND u.Activo = 1
    ORDER BY p.Codigo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_Listar
    @IDUsuarioActor INT,
    @Busqueda       NVARCHAR(100) = NULL,
    @IDRol          INT           = NULL,
    @Activo         BIT           = NULL,
    @OrdenarPor     NVARCHAR(20)  = N'FechaCreacion',   -- Correo | Nombres | FechaCreacion
    @Direccion      NVARCHAR(4)   = N'DESC',            -- ASC | DESC
    @Pagina         INT           = 1,
    @TamanoPagina   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarAdministrador @IDUsuarioActor = @IDUsuarioActor;

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    SELECT  u.IDUsuario, u.Correo, u.Nombres, u.Apellidos, u.Telefono, u.Activo,
            u.FechaCreacion, r.IDRol, r.Nombre AS Rol,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.Usuarios u
    JOIN    dbo.Roles r ON r.IDRol = u.IDRol
    WHERE   (@IDRol  IS NULL OR u.IDRol = @IDRol)
        AND (@Activo IS NULL OR u.Activo = @Activo)
        AND (@Busqueda IS NULL
             OR u.Correo    LIKE N'%' + @Busqueda + N'%'
             OR u.Nombres   LIKE N'%' + @Busqueda + N'%'
             OR u.Apellidos LIKE N'%' + @Busqueda + N'%')
    ORDER BY
        CASE WHEN @OrdenarPor = N'Correo'        AND @Direccion = N'ASC'  THEN u.Correo        END ASC,
        CASE WHEN @OrdenarPor = N'Correo'        AND @Direccion = N'DESC' THEN u.Correo        END DESC,
        CASE WHEN @OrdenarPor = N'Nombres'       AND @Direccion = N'ASC'  THEN u.Nombres       END ASC,
        CASE WHEN @OrdenarPor = N'Nombres'       AND @Direccion = N'DESC' THEN u.Nombres       END DESC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'ASC'  THEN u.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'DESC' THEN u.FechaCreacion END DESC,
        u.IDUsuario DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_CambiarEstado
    @IDUsuarioActor INT,
    @IDUsuario      INT,
    @Activo         BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarAdministrador @IDUsuarioActor = @IDUsuarioActor;

    DECLARE @ActivoActual BIT, @NombreRol NVARCHAR(50), @OtrosAdmins INT,
            @Accion NVARCHAR(20), @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT  @ActivoActual = u.Activo, @NombreRol = r.Nombre
        FROM    dbo.Usuarios u WITH (UPDLOCK, HOLDLOCK)
        JOIN    dbo.Roles r ON r.IDRol = u.IDRol
        WHERE   u.IDUsuario = @IDUsuario;

        IF @ActivoActual IS NULL
            THROW 50012, N'El usuario no existe.', 1;

        IF @ActivoActual = @Activo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDUsuario AS IDUsuario, @Activo AS Activo;
            RETURN;
        END;

        IF @Activo = 0
        BEGIN
            IF @IDUsuario = @IDUsuarioActor
                THROW 50014, N'No puede desactivar su propio usuario.', 1;

            IF @NombreRol = N'Administrador'
            BEGIN
                SELECT @OtrosAdmins = COUNT(*)
                FROM   dbo.Usuarios x WITH (UPDLOCK, HOLDLOCK)
                JOIN   dbo.Roles rx ON rx.IDRol = x.IDRol
                WHERE  rx.Nombre = N'Administrador'
                   AND x.Activo = 1
                   AND x.IDUsuario <> @IDUsuario;

                IF @OtrosAdmins = 0
                    THROW 50015, N'No se puede desactivar al �ltimo administrador activo.', 1;
            END;
        END;

        UPDATE dbo.Usuarios
        SET    Activo = @Activo,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDUsuario = @IDUsuario;

        IF @Activo = 0
            UPDATE dbo.TokensRefresco
            SET    FechaRevocacion = SYSUTCDATETIME()
            WHERE  IDUsuario = @IDUsuario
              AND  FechaRevocacion IS NULL;

        SET @Accion = CASE WHEN @Activo = 0 THEN N'DESACTIVAR' ELSE N'MODIFICAR' END;
        SET @ValorAnterior = (SELECT @ActivoActual AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Activo       AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Usuarios', @Entidad = N'Usuario',
            @IDEntidad = @IDUsuario, @Accion = @Accion,
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDUsuario AS IDUsuario, @Activo AS Activo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Tokens_Guardar
    @IDUsuario       INT,
    @TokenHash       CHAR(64),
    @FechaExpiracion DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE IDUsuario = @IDUsuario AND Activo = 1)
        THROW 50013, N'El usuario no existe o est� inactivo.', 1;

    INSERT INTO dbo.TokensRefresco (IDUsuario, TokenHash, FechaExpiracion)
    VALUES (@IDUsuario, @TokenHash, @FechaExpiracion);

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS IDTokenRefresco;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Tokens_Rotar
    @TokenHashActual      CHAR(64),
    @TokenHashNuevo       CHAR(64),
    @FechaExpiracionNueva DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IDTokenActual BIGINT, @IDUsuario INT, @FechaRevocacion DATETIME2(0),
            @FechaExpiracion DATETIME2(0), @UsuarioActivo BIT, @IDTokenNuevo BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT  @IDTokenActual = t.IDTokenRefresco,
                @IDUsuario = t.IDUsuario,
                @FechaRevocacion = t.FechaRevocacion,
                @FechaExpiracion = t.FechaExpiracion,
                @UsuarioActivo = u.Activo
        FROM    dbo.TokensRefresco t WITH (UPDLOCK, ROWLOCK)
        JOIN    dbo.Usuarios u ON u.IDUsuario = t.IDUsuario
        WHERE   t.TokenHash = @TokenHashActual;

        IF @IDTokenActual IS NULL
            THROW 50020, N'El token de refresco no es v�lido.', 1;

        IF @FechaRevocacion IS NOT NULL
        BEGIN
            UPDATE dbo.TokensRefresco
            SET    FechaRevocacion = SYSUTCDATETIME()
            WHERE  IDUsuario = @IDUsuario
              AND  FechaRevocacion IS NULL;

            COMMIT TRANSACTION;

            THROW 50021, N'Se detect� la reutilizaci�n de un token de refresco; se cerraron todas las sesiones.', 1;
        END;

        IF @FechaExpiracion <= SYSUTCDATETIME() OR @UsuarioActivo = 0
            THROW 50020, N'El token de refresco no es v�lido.', 1;

        INSERT INTO dbo.TokensRefresco (IDUsuario, TokenHash, FechaExpiracion)
        VALUES (@IDUsuario, @TokenHashNuevo, @FechaExpiracionNueva);

        SET @IDTokenNuevo = SCOPE_IDENTITY();

        UPDATE dbo.TokensRefresco
        SET    FechaRevocacion = SYSUTCDATETIME(),
               IDTokenReemplazo = @IDTokenNuevo
        WHERE  IDTokenRefresco = @IDTokenActual;

        COMMIT TRANSACTION;

        SELECT  u.IDUsuario, u.Correo, r.Nombre AS Rol
        FROM    dbo.Usuarios u
        JOIN    dbo.Roles r ON r.IDRol = u.IDRol
        WHERE   u.IDUsuario = @IDUsuario;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Tokens_Revocar
    @TokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TokensRefresco
    SET    FechaRevocacion = SYSUTCDATETIME()
    WHERE  TokenHash = @TokenHash
      AND  FechaRevocacion IS NULL;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'004_Seguridad_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'004_Seguridad_Procedimientos.sql');
GO

CREATE OR ALTER PROCEDURE dbo.SP_Usuarios_CrearAdministradorSemilla
    @Correo       NVARCHAR(255),
    @PasswordHash NVARCHAR(255),
    @Nombres      NVARCHAR(100),
    @Apellidos    NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @IDRol INT,
        @IDUsuario INT,
        @RolExistente NVARCHAR(50),
        @UsuarioActivo BIT,
        @ValorNuevo NVARCHAR(MAX);

    SET @Correo = LOWER(LTRIM(RTRIM(@Correo)));
    SET @Nombres = LTRIM(RTRIM(@Nombres));
    SET @Apellidos = LTRIM(RTRIM(@Apellidos));

    IF @Correo = N'' OR @PasswordHash = N''
       OR @Nombres = N'' OR @Apellidos = N''
        THROW 50053, N'Los datos del administrador semilla son obligatorios.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IDRol = IDRol
        FROM dbo.Roles WITH (UPDLOCK, HOLDLOCK)
        WHERE Nombre = N'Administrador'
          AND Activo = 1;

        IF @IDRol IS NULL
            THROW 50001, N'El rol Administrador no existe o est� inactivo.', 1;

        SELECT
            @IDUsuario = u.IDUsuario,
            @RolExistente = r.Nombre,
            @UsuarioActivo = u.Activo
        FROM dbo.Usuarios u WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.Roles r ON r.IDRol = u.IDRol
        WHERE u.Correo = @Correo;

        IF @IDUsuario IS NOT NULL
        BEGIN
            IF @RolExistente <> N'Administrador'
                THROW 50022, N'El correo configurado para el administrador semilla ya pertenece a otro rol.', 1;

            IF @UsuarioActivo = 0
                THROW 50023, N'El administrador semilla ya existe, pero est� inactivo. Debe revisarse manualmente.', 1;

            COMMIT TRANSACTION;

            SELECT @IDUsuario AS IDUsuario, CAST(0 AS BIT) AS Creado;
            RETURN;
        END;

        INSERT INTO dbo.Usuarios (
            IDRol,
            Correo,
            PasswordHash,
            Nombres,
            Apellidos
        )
        VALUES (
            @IDRol,
            @Correo,
            @PasswordHash,
            @Nombres,
            @Apellidos
        );

        SET @IDUsuario = CONVERT(INT, SCOPE_IDENTITY());

        SET @ValorNuevo = (
            SELECT
                @IDUsuario AS IDUsuario,
                @Correo AS Correo,
                @Nombres AS Nombres,
                @Apellidos AS Apellidos,
                @IDRol AS IDRol,
                CAST(1 AS BIT) AS Activo
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuario,
            @Modulo = N'Usuarios',
            @Entidad = N'Usuario',
            @IDEntidad = @IDUsuario,
            @Accion = N'CREAR',
            @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDUsuario AS IDUsuario, CAST(1 AS BIT) AS Creado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50010, N'El correo ya est� registrado.', 1;

        THROW;
    END CATCH;
END;
GO

/* Catalogo */
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
        THROW 50016, N'No tiene permisos para realizar esta acci�n.', 1;
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
        THROW 50053, N'El nombre de la categor�a es obligatorio.', 1;

    DECLARE @IDCategoria INT, @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Categorias WITH (UPDLOCK, HOLDLOCK) WHERE Nombre = @Nombre)
            THROW 50041, N'Ya existe una categor�a con ese nombre.', 1;

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
            THROW 50041, N'Ya existe una categor�a con ese nombre.', 1;
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
        THROW 50053, N'El nombre de la categor�a es obligatorio.', 1;

    DECLARE @NombreActual NVARCHAR(100), @DescripcionActual NVARCHAR(255),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @NombreActual = Nombre, @DescripcionActual = Descripcion
        FROM   dbo.Categorias WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCategoria = @IDCategoria;

        IF @NombreActual IS NULL
            THROW 50040, N'La categor�a no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Categorias WHERE Nombre = @Nombre AND IDCategoria <> @IDCategoria)
            THROW 50041, N'Ya existe una categor�a con ese nombre.', 1;

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
            THROW 50041, N'Ya existe una categor�a con ese nombre.', 1;
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
            THROW 50040, N'La categor�a no existe.', 1;

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
            THROW 50040, N'La categor�a no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Productos WITH (UPDLOCK, HOLDLOCK) WHERE IDCategoria = @IDCategoria)
            THROW 50042, N'La categor�a tiene productos asociados; desact�vela en lugar de eliminarla.', 1;

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
        THROW 50053, N'La lista de variantes no es un JSON v�lido.', 1;
    IF @Imagenes IS NOT NULL AND ISJSON(@Imagenes) <> 1
        THROW 50053, N'La lista de im�genes no es un JSON v�lido.', 1;

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
        THROW 50056, N'Alguno de los atributos no existe o est� inactivo.', 1;

    UPDATE v
    SET    Combinacion = ISNULL((
               SELECT STRING_AGG(CONCAT(x.Atributo, N'=', x.Valor), N'|') WITHIN GROUP (ORDER BY x.Atributo)
               FROM @VarAtr x WHERE x.Orden = v.Orden), N'')
    FROM   @Var v;

    IF EXISTS (SELECT 1 FROM @Var GROUP BY Combinacion HAVING COUNT(*) > 1)
        THROW 50055, N'Dos variantes tienen la misma combinaci�n de atributos.', 1;

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
            THROW 50051, N'La categor�a no existe o est� inactiva.', 1;

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
            THROW 50051, N'La categor�a no existe o est� inactiva.', 1;

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
        THROW 50053, N'La lista de im�genes no es un JSON v�lido.', 1;

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
        THROW 50053, N'La lista de atributos no es un JSON v�lido.', 1;

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
        THROW 50056, N'Alguno de los atributos no existe o est� inactivo.', 1;

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
            THROW 50055, N'Ya existe una variante con esa combinaci�n de atributos.', 1;

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
        THROW 50053, N'La lista de atributos no es un JSON v�lido.', 1;

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
            THROW 50056, N'Alguno de los atributos no existe o est� inactivo.', 1;

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
            THROW 50055, N'Ya existe una variante con esa combinaci�n de atributos.', 1;

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
        THROW 50059, N'El precio m�nimo no puede ser mayor al m�ximo.', 1;

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
/*Inventario*/
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
            THROW 50062, N'La existencia reservada resultar�a negativa.', 1;
        IF @ExistenciaNueva < @NuevaReservada
            THROW 50063, N'El movimiento dejar�a la existencia por debajo de las unidades reservadas.', 1;

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
   descuenta lo reservado. Debe llamarse dentro de la transacci�n de creaci�n
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
            THROW 50070, N'La reserva venci� o ya no est� activa; vuelva a iniciar el pago.', 1;

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
   - At�mico: reserva todo o nada. Si dos clientes piden la �ltima unidad,
     solo uno la obtiene; el otro recibe 50067 con un mensaje claro.
   - Libera antes la reserva activa del propio usuario y las vencidas que
     afecten a estas variantes, as� un job ca�do no bloquea el stock. */
CREATE OR ALTER PROCEDURE dbo.SP_Inventario_ReservarExistencia
    @IDUsuarioActor INT,
    @Items          NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'COMPRAR';

    IF @Items IS NULL OR ISJSON(@Items) <> 1
        THROW 50053, N'La lista de productos a reservar no es un JSON v�lido.', 1;

    DECLARE @MinutosVigencia INT = 15;
    DECLARE @IDReserva INT, @Vencimiento DATETIME2(0), @Falla NVARCHAR(400),
            @IDPrevia INT, @IDVencida INT = 0, @Filas INT, @Total INT;

    DECLARE @Crudo TABLE (IDVariante INT NULL, Cantidad INT NULL);
    DECLARE @Solicitud TABLE (IDVariante INT NOT NULL PRIMARY KEY, Cantidad INT NOT NULL);

    INSERT INTO @Crudo (IDVariante, Cantidad)
    SELECT j.IDVariante, j.Cantidad
    FROM OPENJSON(@Items) WITH (IDVariante INT '$.idVariante', Cantidad INT '$.cantidad') j;

    IF NOT EXISTS (SELECT 1 FROM @Crudo)
        THROW 50053, N'La lista de productos a reservar est� vac�a.', 1;
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
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' no est� disponible para la venta.')
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

        /* 4) Reserva at�mica: la condici�n del UPDATE es la barrera final contra la sobreventa */
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

/* El due�o de la reserva (o quien gestiona inventario) la libera antes de que venza.
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
   transacci�n; si una falla (p. ej. deadlock) se reintenta en la siguiente corrida. */
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

/*Carrito Compras */
CREATE OR ALTER PROCEDURE Interno.SP_Carrito_ResolverCarrito
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @Crear      BIT      = 0,
    @Bloquear   BIT      = 1,
    @IDCarrito  INT      = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF (@IDUsuario IS NULL AND @TokenHash IS NULL) OR (@IDUsuario IS NOT NULL AND @TokenHash IS NOT NULL)
        THROW 50080, N'Debe indicar el usuario o el token del carrito de invitado (solo uno).', 1;

    IF @TokenHash IS NOT NULL AND (LEN(@TokenHash) <> 64 OR @TokenHash LIKE N'%[^0-9a-fA-F]%')
        THROW 50053, N'El token del carrito no es v�lido.', 1;

    IF @IDUsuario IS NOT NULL
        EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    SET @IDCarrito = NULL;

    IF @Bloquear = 1
    BEGIN
        IF @IDUsuario IS NOT NULL
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
            WHERE IDUsuario = @IDUsuario AND Estado = N'ACTIVO';
        ELSE
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
            WHERE TokenHash = @TokenHash AND Estado = N'ACTIVO';
    END
    ELSE
    BEGIN
        IF @IDUsuario IS NOT NULL
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos
            WHERE IDUsuario = @IDUsuario AND Estado = N'ACTIVO';
        ELSE
            SELECT @IDCarrito = IDCarrito FROM dbo.Carritos
            WHERE TokenHash = @TokenHash AND Estado = N'ACTIVO';
    END;

    IF @IDCarrito IS NULL AND @Crear = 1
    BEGIN
        INSERT INTO dbo.Carritos (IDUsuario, TokenHash) VALUES (@IDUsuario, @TokenHash);
        SET @IDCarrito = SCOPE_IDENTITY();
    END;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Carrito_LiberarReservaUsuario
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDReserva INT;

    SELECT @IDReserva = IDReserva
    FROM   dbo.Reservas WITH (UPDLOCK, HOLDLOCK)
    WHERE  IDUsuario = @IDUsuario AND Estado = N'ACTIVA';

    IF @IDReserva IS NOT NULL
        EXEC Interno.SP_Inventario_CerrarReserva @IDReserva = @IDReserva, @NuevoEstado = N'LIBERADA';
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_Obtener
    @IDUsuario INT      = NULL,
    @TokenHash CHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDCarrito INT;

    EXEC Interno.SP_Carrito_ResolverCarrito
        @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 0, @IDCarrito = @IDCarrito OUTPUT;

    SELECT  @IDCarrito AS IDCarrito, t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva, t.Lineas
    FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;

    SELECT  d.IDVariante,
            v.SKU,
            p.IDProducto,
            p.Nombre AS Producto,
            (SELECT STRING_AGG(CONCAT(a.Nombre, N': ', va.Valor), N', ') WITHIN GROUP (ORDER BY a.Nombre)
             FROM dbo.VarianteAtributos va
             JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
             WHERE va.IDVariante = v.IDVariante) AS Atributos,
            v.Precio,
            d.Cantidad,
            CAST(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio AS DECIMAL(18,2)) AS Subtotal,
            v.ExistenciaDisponible AS Disponible,
            CAST(CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END AS BIT) AS Vendible,
            CAST(CASE WHEN d.Cantidad > v.ExistenciaDisponible THEN 1 ELSE 0 END AS BIT)            AS ExcedeExistencia,
            i.Url AS ImagenPrincipal
    FROM    dbo.CarritosDetalle d
    JOIN    dbo.Variantes v  ON v.IDVariante = d.IDVariante
    JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
    JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
    LEFT JOIN dbo.ImagenesProducto i ON i.IDProducto = p.IDProducto AND i.EsPrincipal = 1
    WHERE   d.IDCarrito = @IDCarrito
    ORDER BY d.FechaCreacion, d.IDVariante;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_AgregarProducto
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @IDVariante INT,
    @Cantidad   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 50066, N'La cantidad debe ser mayor a cero.', 1;

    DECLARE @IDCarrito INT, @SKU NVARCHAR(50), @Disponible INT, @Vendible BIT,
            @Actual INT = 0, @Nueva INT, @Mensaje NVARCHAR(400);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 1, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        SELECT  @SKU = v.SKU,
                @Disponible = v.ExistenciaDisponible,
                @Vendible = CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END
        FROM    dbo.Variantes v
        JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
        JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE   v.IDVariante = @IDVariante;

        IF @SKU IS NULL
            THROW 50057, N'El producto solicitado no existe.', 1;
        IF @Vendible = 0
            THROW 50068, N'El producto no est� disponible para la venta.', 1;

        SELECT @Actual = Cantidad
        FROM   dbo.CarritosDetalle
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        SET @Nueva = @Actual + @Cantidad;

        IF @Nueva > @Disponible
        BEGIN
            SET @Mensaje = CONCAT(N'No hay existencia suficiente del SKU ', @SKU, N': tiene ', @Actual,
                                  N' en el carrito, solicita ', @Cantidad, N' m�s y hay ', @Disponible, N' disponible(s).');
            THROW 50082, @Mensaje, 1;
        END;

        UPDATE dbo.CarritosDetalle
        SET    Cantidad = @Nueva
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        IF @@ROWCOUNT = 0
            INSERT INTO dbo.CarritosDetalle (IDCarrito, IDVariante, Cantidad)
            VALUES (@IDCarrito, @IDVariante, @Nueva);

        UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarrito;

        IF @IDUsuario IS NOT NULL
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDCarrito AS IDCarrito, @IDVariante AS IDVariante, @Nueva AS Cantidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
           AND (ERROR_MESSAGE() LIKE N'%UX_Carritos_UsuarioActivo%' OR ERROR_MESSAGE() LIKE N'%UX_Carritos_TokenHash%')
            THROW 50084, N'El carrito se est� modificando en otra solicitud; intente de nuevo.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_ActualizarCantidad
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @IDVariante INT,
    @Cantidad   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 50066, N'La cantidad debe ser mayor a cero.', 1;

    DECLARE @IDCarrito INT, @SKU NVARCHAR(50), @Disponible INT, @Vendible BIT,
            @Existe INT, @Mensaje NVARCHAR(400);

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        SELECT @Existe = IDVariante
        FROM   dbo.CarritosDetalle
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        IF @Existe IS NULL
            THROW 50083, N'El producto no est� en el carrito.', 1;

        SELECT  @SKU = v.SKU,
                @Disponible = v.ExistenciaDisponible,
                @Vendible = CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END
        FROM    dbo.Variantes v
        JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
        JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
        WHERE   v.IDVariante = @IDVariante;

        IF @Vendible = 0
            THROW 50068, N'El producto no est� disponible para la venta.', 1;

        IF @Cantidad > @Disponible
        BEGIN
            SET @Mensaje = CONCAT(N'No hay existencia suficiente del SKU ', @SKU, N': solicita ', @Cantidad,
                                  N' y hay ', @Disponible, N' disponible(s).');
            THROW 50082, @Mensaje, 1;
        END;

        UPDATE dbo.CarritosDetalle
        SET    Cantidad = @Cantidad
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarrito;

        IF @IDUsuario IS NOT NULL
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDCarrito AS IDCarrito, @IDVariante AS IDVariante, @Cantidad AS Cantidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_EliminarProducto
    @IDUsuario  INT      = NULL,
    @TokenHash  CHAR(64) = NULL,
    @IDVariante INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IDCarrito INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        DELETE FROM dbo.CarritosDetalle
        WHERE  IDCarrito = @IDCarrito AND IDVariante = @IDVariante;

        IF @@ROWCOUNT = 0
            THROW 50083, N'El producto no est� en el carrito.', 1;

        UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarrito;

        IF @IDUsuario IS NOT NULL
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT @IDCarrito AS IDCarrito, @IDVariante AS IDVariante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_Fusionar
    @IDUsuario INT,
    @TokenHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @IDUsuario IS NULL OR @TokenHash IS NULL
        THROW 50080, N'Debe indicar el usuario y el token del carrito de invitado.', 1;
    IF LEN(@TokenHash) <> 64 OR @TokenHash LIKE N'%[^0-9a-fA-F]%'
        THROW 50053, N'El token del carrito no es v�lido.', 1;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuario, @CodigoPermiso = N'COMPRAR';

    DECLARE @IDInvitado INT, @IDCarritoUsuario INT, @Fusionado BIT = 0;
    DECLARE @Plan TABLE (
        IDVariante   INT PRIMARY KEY,
        SKU          NVARCHAR(50) NOT NULL,
        CantInvitado INT NOT NULL,
        CantUsuario  INT NOT NULL,
        Objetivo     INT NOT NULL
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @IDCarritoUsuario = IDCarrito
        FROM   dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDUsuario = @IDUsuario AND Estado = N'ACTIVO';

        SELECT @IDInvitado = IDCarrito
        FROM   dbo.Carritos WITH (UPDLOCK, HOLDLOCK)
        WHERE  TokenHash = @TokenHash AND Estado = N'ACTIVO';

        IF @IDInvitado IS NOT NULL
        BEGIN
            IF @IDCarritoUsuario IS NULL
            BEGIN
                UPDATE dbo.Carritos
                SET    IDUsuario = @IDUsuario, TokenHash = NULL, FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDCarrito = @IDInvitado;

                SET @IDCarritoUsuario = @IDInvitado;
            END
            ELSE
            BEGIN
                INSERT INTO @Plan (IDVariante, SKU, CantInvitado, CantUsuario, Objetivo)
                SELECT  g.IDVariante, v.SKU, g.Cantidad, ISNULL(u.Cantidad, 0),
                        CASE
                            WHEN NOT (v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1)
                                THEN ISNULL(u.Cantidad, 0)
                            WHEN ISNULL(u.Cantidad, 0) + g.Cantidad <= v.ExistenciaDisponible
                                THEN ISNULL(u.Cantidad, 0) + g.Cantidad
                            WHEN v.ExistenciaDisponible > ISNULL(u.Cantidad, 0)
                                THEN v.ExistenciaDisponible
                            ELSE ISNULL(u.Cantidad, 0)
                        END
                FROM    dbo.CarritosDetalle g
                JOIN    dbo.Variantes v  ON v.IDVariante = g.IDVariante
                JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
                JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
                LEFT JOIN dbo.CarritosDetalle u
                        ON u.IDCarrito = @IDCarritoUsuario AND u.IDVariante = g.IDVariante
                WHERE   g.IDCarrito = @IDInvitado;

                UPDATE u
                SET    u.Cantidad = p.Objetivo
                FROM   dbo.CarritosDetalle u
                JOIN   @Plan p ON p.IDVariante = u.IDVariante
                WHERE  u.IDCarrito = @IDCarritoUsuario
                  AND  p.Objetivo <> u.Cantidad;

                INSERT INTO dbo.CarritosDetalle (IDCarrito, IDVariante, Cantidad)
                SELECT @IDCarritoUsuario, IDVariante, Objetivo
                FROM   @Plan
                WHERE  CantUsuario = 0 AND Objetivo > 0;

                UPDATE dbo.Carritos SET FechaActualizacion = SYSUTCDATETIME() WHERE IDCarrito = @IDCarritoUsuario;

                UPDATE dbo.Carritos
                SET    Estado = N'FUSIONADO', IDUsuario = @IDUsuario, TokenHash = NULL,
                       FechaActualizacion = SYSUTCDATETIME()
                WHERE  IDCarrito = @IDInvitado;
            END;

            SET @Fusionado = 1;
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;
        END;

        COMMIT TRANSACTION;

        SELECT @IDCarritoUsuario AS IDCarrito, @Fusionado AS Fusionado;

        SELECT IDVariante, SKU, CantInvitado AS Solicitada, Objetivo - CantUsuario AS Aplicada
        FROM   @Plan
        WHERE  Objetivo - CantUsuario < CantInvitado
        ORDER BY IDVariante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'014_Carrito_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'014_Carrito_Procedimientos.sql');
GO
/*Cupones*/
CREATE OR ALTER FUNCTION dbo.FU_Cupones_MensajeRechazo (@Codigo NVARCHAR(30))
RETURNS TABLE
AS
RETURN (
    SELECT m.Mensaje, m.Estado
    FROM (VALUES
        (N'INACTIVO',                N'El cup�n no est� activo.',                                                   1),
        (N'NO_VIGENTE',              N'El cup�n a�n no est� vigente.',                                              2),
        (N'VENCIDO',                 N'El cup�n est� vencido.',                                                     3),
        (N'AGOTADO',                 N'El cup�n ya alcanz� su l�mite total de usos.',                               4),
        (N'LIMITE_CLIENTE',          N'Ya alcanz� el l�mite de usos de este cup�n por cliente.',                    5),
        (N'CARRITO_VACIO',           N'El carrito est� vac�o; agregue productos para usar el cup�n.',               6),
        (N'SIN_PRODUCTOS_CATEGORIA', N'El carrito no tiene productos de la categor�a a la que aplica el cup�n.',    7),
        (N'MINIMO_NO_ALCANZADO',     N'El subtotal del carrito no alcanza la compra m�nima del cup�n.',             8)
    ) AS m (Codigo, Mensaje, Estado)
    WHERE m.Codigo = @Codigo
);
GO

CREATE OR ALTER FUNCTION dbo.FU_Cupones_CalculoDescuento
(
    @IDCupon INT,
    @IDCarrito INT,
    @IDUsuario INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        z.IDCupon,
        z.SubtotalCarrito,
        z.SubtotalElegible,
        z.CodigoRechazo,
        CAST(
            CASE
                WHEN z.CodigoRechazo IS NOT NULL THEN 0
                WHEN z.TipoDescuento = N'PORCENTAJE'
                    THEN ROUND(z.SubtotalElegible * z.Valor / 100, 2)
                WHEN z.Valor > z.SubtotalElegible
                    THEN z.SubtotalElegible
                ELSE z.Valor
            END
            AS DECIMAL(18,2)
        ) AS Descuento
    FROM
    (
        SELECT
            c.IDCupon,
            c.TipoDescuento,
            c.Valor,
            s.SubtotalCarrito,
            s.SubtotalElegible,
            CASE
                WHEN c.Activo = 0 THEN N'INACTIVO'
                WHEN SYSUTCDATETIME() < c.FechaInicio THEN N'NO_VIGENTE'
                WHEN SYSUTCDATETIME() > c.FechaFin THEN N'VENCIDO'
                WHEN c.LimiteUsosTotal IS NOT NULL
                     AND c.UsosActuales >= c.LimiteUsosTotal
                    THEN N'AGOTADO'
                WHEN c.LimiteUsosPorCliente IS NOT NULL
                     AND u.Usos >= c.LimiteUsosPorCliente
                    THEN N'LIMITE_CLIENTE'
                WHEN s.SubtotalCarrito <= 0 THEN N'CARRITO_VACIO'
                WHEN c.IDCategoria IS NOT NULL
                     AND s.SubtotalElegible <= 0
                    THEN N'SIN_PRODUCTOS_CATEGORIA'
                WHEN s.SubtotalCarrito < c.MontoMinimo
                    THEN N'MINIMO_NO_ALCANZADO'
            END AS CodigoRechazo
        FROM dbo.Cupones c

        CROSS APPLY
        (
            SELECT
                CAST(
                    ISNULL(
                        SUM(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio),
                        0
                    ) AS DECIMAL(18,2)
                ) AS SubtotalCarrito,

                CAST(
                    CASE
                        WHEN c.IDCategoria IS NULL THEN
                            ISNULL(
                                SUM(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio),
                                0
                            )
                        ELSE
                            ISNULL(
                                (
                                    SELECT SUM(
                                        CAST(d2.Cantidad AS DECIMAL(18,2)) * v2.Precio
                                    )
                                    FROM dbo.CarritosDetalle d2
                                    INNER JOIN dbo.Variantes v2
                                        ON v2.IDVariante = d2.IDVariante
                                    INNER JOIN dbo.Productos p2
                                        ON p2.IDProducto = v2.IDProducto
                                    INNER JOIN dbo.Categorias ca2
                                        ON ca2.IDCategoria = p2.IDCategoria
                                    WHERE d2.IDCarrito = @IDCarrito
                                      AND v2.Activo = 1
                                      AND p2.Activo = 1
                                      AND ca2.Activo = 1
                                      AND p2.IDCategoria = c.IDCategoria
                                ),
                                0
                            )
                    END AS DECIMAL(18,2)
                ) AS SubtotalElegible

            FROM dbo.CarritosDetalle d
            INNER JOIN dbo.Variantes v
                ON v.IDVariante = d.IDVariante
            INNER JOIN dbo.Productos p
                ON p.IDProducto = v.IDProducto
            INNER JOIN dbo.Categorias ca
                ON ca.IDCategoria = p.IDCategoria
            WHERE d.IDCarrito = @IDCarrito
              AND v.Activo = 1
              AND p.Activo = 1
              AND ca.Activo = 1
        ) s

        CROSS APPLY
        (
            SELECT COUNT(*) AS Usos
            FROM dbo.UsosCupones uc
            WHERE uc.IDCupon = c.IDCupon
              AND uc.IDUsuario = @IDUsuario
              AND uc.Estado = N'APLICADO'
        ) u

        WHERE c.IDCupon = @IDCupon
    ) z
);
GO

CREATE OR ALTER FUNCTION dbo.FU_Carrito_Totales (@IDCarrito INT)
RETURNS TABLE
AS
RETURN (
    SELECT  x.Subtotal,
            x.Descuento,
            x.Total,
            CAST(ROUND(x.Total / 1.12, 2) AS DECIMAL(18,2))           AS BaseImponible,
            CAST(x.Total - ROUND(x.Total / 1.12, 2) AS DECIMAL(18,2)) AS Iva,
            x.Lineas,
            x.IDCupon,
            x.CuponRechazo
    FROM (
        SELECT  s.Subtotal,
                s.Lineas,
                CAST(ISNULL(d.Descuento, 0) AS DECIMAL(18,2))                 AS Descuento,
                CAST(s.Subtotal - ISNULL(d.Descuento, 0) AS DECIMAL(18,2))    AS Total,
                ca.IDCupon,
                d.CodigoRechazo                                               AS CuponRechazo
        FROM (
            SELECT  CAST(ISNULL(SUM(CAST(dt.Cantidad AS DECIMAL(18,2)) * v.Precio), 0) AS DECIMAL(18,2)) AS Subtotal,
                    COUNT(dt.IDVariante) AS Lineas
            FROM    dbo.CarritosDetalle dt
            JOIN    dbo.Variantes v   ON v.IDVariante = dt.IDVariante
            JOIN    dbo.Productos p   ON p.IDProducto = v.IDProducto
            JOIN    dbo.Categorias c  ON c.IDCategoria = p.IDCategoria
            WHERE   dt.IDCarrito = @IDCarrito
                AND v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1
        ) s
        LEFT JOIN dbo.Carritos ca ON ca.IDCarrito = @IDCarrito
        OUTER APPLY dbo.FU_Cupones_CalculoDescuento(ca.IDCupon, @IDCarrito, ca.IDUsuario) d
    ) x
);
GO

CREATE OR ALTER PROCEDURE Interno.SP_Cupones_ValidarDatos
    @TipoDescuento        NVARCHAR(12),
    @Valor                DECIMAL(12,2),
    @IDCategoria          INT,
    @MontoMinimo          DECIMAL(12,2),
    @FechaInicio          DATETIME2(0),
    @FechaFin             DATETIME2(0),
    @LimiteUsosTotal      INT,
    @LimiteUsosPorCliente INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @TipoDescuento IS NULL OR @TipoDescuento NOT IN (N'PORCENTAJE', N'MONTO_FIJO')
        THROW 50053, N'El tipo de descuento debe ser PORCENTAJE o MONTO_FIJO.', 1;
    IF @Valor IS NULL OR @Valor <= 0
        THROW 50053, N'El valor del descuento debe ser mayor a cero.', 1;
    IF @TipoDescuento = N'PORCENTAJE' AND @Valor > 100
        THROW 50053, N'El porcentaje de descuento no puede superar 100.', 1;
    IF @MontoMinimo IS NULL OR @MontoMinimo < 0
        THROW 50053, N'El monto m�nimo no puede ser negativo.', 1;
    IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaFin <= @FechaInicio
        THROW 50053, N'La vigencia no es v�lida: la fecha de fin debe ser posterior a la de inicio.', 1;
    IF @LimiteUsosTotal IS NOT NULL AND @LimiteUsosTotal <= 0
        THROW 50053, N'El l�mite total de usos debe ser mayor a cero.', 1;
    IF @LimiteUsosPorCliente IS NOT NULL AND @LimiteUsosPorCliente <= 0
        THROW 50053, N'El l�mite de usos por cliente debe ser mayor a cero.', 1;
    IF @IDCategoria IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Categorias WHERE IDCategoria = @IDCategoria)
        THROW 50040, N'La categor�a no existe.', 1;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Cupones_RegistrarUso
    @IDCupon        INT,
    @IDUsuario      INT,
    @IDPedido       INT,
    @MontoDescuento DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Filas INT, @Rechazo NVARCHAR(30), @Mensaje NVARCHAR(255), @Estado INT;

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        UPDATE dbo.Cupones
        SET    UsosActuales = UsosActuales + 1,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCupon = @IDCupon
          AND  Activo = 1
          AND  SYSUTCDATETIME() >= FechaInicio
          AND  SYSUTCDATETIME() <= FechaFin
          AND  (LimiteUsosTotal IS NULL OR UsosActuales < LimiteUsosTotal);

        SET @Filas = @@ROWCOUNT;

        IF @Filas = 0
        BEGIN
            SELECT @Rechazo = CASE
                        WHEN c.Activo = 0 THEN N'INACTIVO'
                        WHEN SYSUTCDATETIME() < c.FechaInicio THEN N'NO_VIGENTE'
                        WHEN SYSUTCDATETIME() > c.FechaFin THEN N'VENCIDO'
                        ELSE N'AGOTADO' END
            FROM   dbo.Cupones c
            WHERE  c.IDCupon = @IDCupon;

            IF @Rechazo IS NULL
                THROW 50091, N'El cup�n no existe.', 1;

            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(@Rechazo) m;
            THROW 50095, @Mensaje, @Estado;
        END;

        IF EXISTS (
            SELECT 1
            FROM   dbo.Cupones c
            WHERE  c.IDCupon = @IDCupon
              AND  c.LimiteUsosPorCliente IS NOT NULL
              AND  (SELECT COUNT(*) FROM dbo.UsosCupones u
                    WHERE u.IDCupon = c.IDCupon AND u.IDUsuario = @IDUsuario AND u.Estado = N'APLICADO')
                   >= c.LimiteUsosPorCliente
        )
        BEGIN
            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(N'LIMITE_CLIENTE') m;
            THROW 50095, @Mensaje, @Estado;
        END;

        INSERT INTO dbo.UsosCupones (IDCupon, IDUsuario, IDPedido, MontoDescuento)
        VALUES (@IDCupon, @IDUsuario, @IDPedido, @MontoDescuento);

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Cupones_RevertirUso
    @IDPedido INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Revertidos TABLE (IDCupon INT NOT NULL);

    BEGIN TRY
        IF @Propia = 1
        BEGIN
            BEGIN TRANSACTION;
        END;

        UPDATE dbo.UsosCupones
        SET    Estado = N'REVERSADO', FechaReversion = SYSUTCDATETIME()
        OUTPUT inserted.IDCupon INTO @Revertidos (IDCupon)
        WHERE  IDPedido = @IDPedido AND Estado = N'APLICADO';

        UPDATE c
        SET    c.UsosActuales = CASE WHEN c.UsosActuales > 0 THEN c.UsosActuales - 1 ELSE 0 END,
               c.FechaActualizacion = SYSUTCDATETIME()
        FROM   dbo.Cupones c
        JOIN   @Revertidos r ON r.IDCupon = c.IDCupon;

        IF @Propia = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Crear
    @IDUsuarioActor       INT,
    @Codigo               NVARCHAR(30),
    @Descripcion          NVARCHAR(255) = NULL,
    @TipoDescuento        NVARCHAR(12),
    @Valor                DECIMAL(12,2),
    @IDCategoria          INT           = NULL,
    @MontoMinimo          DECIMAL(12,2) = 0,
    @FechaInicio          DATETIME2(0),
    @FechaFin             DATETIME2(0),
    @LimiteUsosTotal      INT           = NULL,
    @LimiteUsosPorCliente INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    SET @MontoMinimo = ISNULL(@MontoMinimo, 0);

    IF @Codigo IS NULL OR LEN(@Codigo) < 3 OR LEN(@Codigo) > 30
       OR @Codigo COLLATE Latin1_General_100_BIN2 LIKE N'%[^A-Z0-9_-]%'
        THROW 50053, N'El c�digo debe tener de 3 a 30 caracteres: letras, n�meros, guion o guion bajo.', 1;

    EXEC Interno.SP_Cupones_ValidarDatos
        @TipoDescuento = @TipoDescuento, @Valor = @Valor, @IDCategoria = @IDCategoria,
        @MontoMinimo = @MontoMinimo, @FechaInicio = @FechaInicio, @FechaFin = @FechaFin,
        @LimiteUsosTotal = @LimiteUsosTotal, @LimiteUsosPorCliente = @LimiteUsosPorCliente;

    DECLARE @IDCupon INT, @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Cupones WITH (UPDLOCK, HOLDLOCK) WHERE Codigo = @Codigo)
            THROW 50090, N'Ya existe un cup�n con ese c�digo.', 1;

        INSERT INTO dbo.Cupones
            (Codigo, Descripcion, TipoDescuento, Valor, IDCategoria, MontoMinimo,
             FechaInicio, FechaFin, LimiteUsosTotal, LimiteUsosPorCliente)
        VALUES
            (@Codigo, @Descripcion, @TipoDescuento, @Valor, @IDCategoria, @MontoMinimo,
             @FechaInicio, @FechaFin, @LimiteUsosTotal, @LimiteUsosPorCliente);

        SET @IDCupon = SCOPE_IDENTITY();

        SET @ValorNuevo = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = N'CREAR', @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF ERROR_NUMBER() IN (2601, 2627)
            THROW 50090, N'Ya existe un cup�n con ese c�digo.', 1;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Actualizar
    @IDUsuarioActor       INT,
    @IDCupon              INT,
    @Descripcion          NVARCHAR(255) = NULL,
    @TipoDescuento        NVARCHAR(12),
    @Valor                DECIMAL(12,2),
    @IDCategoria          INT           = NULL,
    @MontoMinimo          DECIMAL(12,2) = 0,
    @FechaInicio          DATETIME2(0),
    @FechaFin             DATETIME2(0),
    @LimiteUsosTotal      INT           = NULL,
    @LimiteUsosPorCliente INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    SET @Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), N'');
    SET @MontoMinimo = ISNULL(@MontoMinimo, 0);

    EXEC Interno.SP_Cupones_ValidarDatos
        @TipoDescuento = @TipoDescuento, @Valor = @Valor, @IDCategoria = @IDCategoria,
        @MontoMinimo = @MontoMinimo, @FechaInicio = @FechaInicio, @FechaFin = @FechaFin,
        @LimiteUsosTotal = @LimiteUsosTotal, @LimiteUsosPorCliente = @LimiteUsosPorCliente;

    DECLARE @UsosActuales INT, @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @UsosActuales = UsosActuales
        FROM   dbo.Cupones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCupon = @IDCupon;

        IF @UsosActuales IS NULL
            THROW 50091, N'El cup�n no existe.', 1;

        IF @LimiteUsosTotal IS NOT NULL AND @LimiteUsosTotal < @UsosActuales
            THROW 50093, N'El l�mite total de usos no puede ser menor a los usos ya registrados.', 1;

        SET @ValorAnterior = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        UPDATE dbo.Cupones
        SET    Descripcion = @Descripcion, TipoDescuento = @TipoDescuento, Valor = @Valor,
               IDCategoria = @IDCategoria, MontoMinimo = @MontoMinimo,
               FechaInicio = @FechaInicio, FechaFin = @FechaFin,
               LimiteUsosTotal = @LimiteUsosTotal, LimiteUsosPorCliente = @LimiteUsosPorCliente,
               FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCupon = @IDCupon;

        SET @ValorNuevo = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_CambiarEstado
    @IDUsuarioActor INT,
    @IDCupon        INT,
    @Activo         BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    DECLARE @ActivoActual BIT, @Accion NVARCHAR(20),
            @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ActivoActual = Activo
        FROM   dbo.Cupones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDCupon = @IDCupon;

        IF @ActivoActual IS NULL
            THROW 50091, N'El cup�n no existe.', 1;

        IF @ActivoActual = @Activo
        BEGIN
            COMMIT TRANSACTION;
            SELECT @IDCupon AS IDCupon, @Activo AS Activo;
            RETURN;
        END;

        UPDATE dbo.Cupones
        SET    Activo = @Activo, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCupon = @IDCupon;

        SET @Accion = CASE WHEN @Activo = 0 THEN N'DESACTIVAR' ELSE N'MODIFICAR' END;
        SET @ValorAnterior = (SELECT @ActivoActual AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Activo       AS Activo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = @Accion,
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon, @Activo AS Activo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Eliminar
    @IDUsuarioActor INT,
    @IDCupon        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    DECLARE @ValorAnterior NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SET @ValorAnterior = (
            SELECT c.IDCupon, c.Codigo, c.TipoDescuento, c.Valor, c.IDCategoria, c.MontoMinimo,
                   c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.Activo
            FROM dbo.Cupones c WITH (UPDLOCK, HOLDLOCK)
            WHERE c.IDCupon = @IDCupon
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        IF @ValorAnterior IS NULL
            THROW 50091, N'El cup�n no existe.', 1;

        IF EXISTS (SELECT 1 FROM dbo.UsosCupones WHERE IDCupon = @IDCupon)
            THROW 50094, N'El cup�n ya fue utilizado; desact�velo en lugar de eliminarlo.', 1;

        UPDATE dbo.Carritos SET IDCupon = NULL WHERE IDCupon = @IDCupon;
        DELETE FROM dbo.Cupones WHERE IDCupon = @IDCupon;

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Cupones', @Entidad = N'Cupon',
            @IDEntidad = @IDCupon, @Accion = N'ELIMINAR', @ValorAnterior = @ValorAnterior;

        COMMIT TRANSACTION;

        SELECT @IDCupon AS IDCupon;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_ObtenerPorID
    @IDUsuarioActor INT,
    @IDCupon        INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    SELECT  c.IDCupon, c.Codigo, c.Descripcion, c.TipoDescuento, c.Valor, c.IDCategoria, ca.Nombre AS Categoria,
            c.MontoMinimo, c.FechaInicio, c.FechaFin, c.LimiteUsosTotal, c.LimiteUsosPorCliente,
            c.UsosActuales, c.Activo, c.FechaCreacion, c.FechaActualizacion
    FROM    dbo.Cupones c
    LEFT JOIN dbo.Categorias ca ON ca.IDCategoria = c.IDCategoria
    WHERE   c.IDCupon = @IDCupon;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Cupones_Listar
    @IDUsuarioActor INT,
    @Busqueda       NVARCHAR(100) = NULL,
    @Estado         NVARCHAR(12)  = NULL,
    @IDCategoria    INT           = NULL,
    @OrdenarPor     NVARCHAR(20)  = N'FechaFin',   -- Codigo | FechaFin | UsosActuales | FechaCreacion
    @Direccion      NVARCHAR(4)   = N'DESC',       -- ASC | DESC
    @Pagina         INT           = 1,
    @TamanoPagina   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CUPONES_GESTIONAR';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    ;WITH Datos AS (
        SELECT  c.IDCupon, c.Codigo, c.Descripcion, c.TipoDescuento, c.Valor, c.IDCategoria,
                ca.Nombre AS Categoria, c.MontoMinimo, c.FechaInicio, c.FechaFin,
                c.LimiteUsosTotal, c.LimiteUsosPorCliente, c.UsosActuales, c.Activo, c.FechaCreacion,
                CASE
                    WHEN c.Activo = 0 THEN N'INACTIVO'
                    WHEN SYSUTCDATETIME() < c.FechaInicio THEN N'PROGRAMADO'
                    WHEN SYSUTCDATETIME() > c.FechaFin THEN N'VENCIDO'
                    WHEN c.LimiteUsosTotal IS NOT NULL AND c.UsosActuales >= c.LimiteUsosTotal THEN N'AGOTADO'
                    ELSE N'VIGENTE'
                END AS Estado
        FROM    dbo.Cupones c
        LEFT JOIN dbo.Categorias ca ON ca.IDCategoria = c.IDCategoria
        WHERE   (@IDCategoria IS NULL OR c.IDCategoria = @IDCategoria)
            AND (@Busqueda IS NULL
                 OR c.Codigo      LIKE N'%' + @Busqueda + N'%'
                 OR c.Descripcion LIKE N'%' + @Busqueda + N'%')
    )
    SELECT  d.*, COUNT(*) OVER () AS TotalRegistros
    FROM    Datos d
    WHERE   (@Estado IS NULL OR d.Estado = @Estado)
    ORDER BY
        CASE WHEN @OrdenarPor = N'Codigo'        AND @Direccion = N'ASC'  THEN d.Codigo        END ASC,
        CASE WHEN @OrdenarPor = N'Codigo'        AND @Direccion = N'DESC' THEN d.Codigo        END DESC,
        CASE WHEN @OrdenarPor = N'FechaFin'      AND @Direccion = N'ASC'  THEN d.FechaFin      END ASC,
        CASE WHEN @OrdenarPor = N'FechaFin'      AND @Direccion = N'DESC' THEN d.FechaFin      END DESC,
        CASE WHEN @OrdenarPor = N'UsosActuales'  AND @Direccion = N'ASC'  THEN d.UsosActuales  END ASC,
        CASE WHEN @OrdenarPor = N'UsosActuales'  AND @Direccion = N'DESC' THEN d.UsosActuales  END DESC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'ASC'  THEN d.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'FechaCreacion' AND @Direccion = N'DESC' THEN d.FechaCreacion END DESC,
        d.IDCupon DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_AplicarCupon
    @IDUsuario INT,
    @Codigo    NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    IF @Codigo IS NULL OR @Codigo = N''
        THROW 50053, N'Indique el c�digo del cup�n.', 1;

    DECLARE @IDCarrito INT, @IDCupon INT, @MontoMinimo DECIMAL(12,2),
            @Rechazo NVARCHAR(30), @Mensaje NVARCHAR(255), @Estado INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = NULL, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        SELECT @IDCupon = IDCupon, @MontoMinimo = MontoMinimo
        FROM   dbo.Cupones
        WHERE  Codigo = @Codigo;

        IF @IDCupon IS NULL
            THROW 50091, N'El cup�n no existe.', 1;

        SELECT @Rechazo = CodigoRechazo
        FROM   dbo.FU_Cupones_CalculoDescuento(@IDCupon, @IDCarrito, @IDUsuario);

        IF @Rechazo IS NOT NULL
        BEGIN
            SELECT @Mensaje = m.Mensaje, @Estado = m.Estado FROM dbo.FU_Cupones_MensajeRechazo(@Rechazo) m;
            IF @Rechazo = N'MINIMO_NO_ALCANZADO'
                SET @Mensaje = CONCAT(N'La compra m�nima para este cup�n es Q', CONVERT(NVARCHAR(30), @MontoMinimo), N'.');
            THROW 50095, @Mensaje, @Estado;
        END;

        UPDATE dbo.Carritos
        SET    IDCupon = @IDCupon, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCarrito = @IDCarrito;

        EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT  @IDCarrito AS IDCarrito, t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_QuitarCupon
    @IDUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IDCarrito INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Interno.SP_Carrito_ResolverCarrito
            @IDUsuario = @IDUsuario, @TokenHash = NULL, @Crear = 0, @Bloquear = 1, @IDCarrito = @IDCarrito OUTPUT;

        IF @IDCarrito IS NULL
            THROW 50081, N'El carrito no existe.', 1;

        UPDATE dbo.Carritos
        SET    IDCupon = NULL, FechaActualizacion = SYSUTCDATETIME()
        WHERE  IDCarrito = @IDCarrito AND IDCupon IS NOT NULL;

        IF @@ROWCOUNT > 0
            EXEC Interno.SP_Carrito_LiberarReservaUsuario @IDUsuario = @IDUsuario;

        COMMIT TRANSACTION;

        SELECT  @IDCarrito AS IDCarrito, t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Carrito_Obtener
    @IDUsuario INT      = NULL,
    @TokenHash CHAR(64) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IDCarrito INT;

    EXEC Interno.SP_Carrito_ResolverCarrito
        @IDUsuario = @IDUsuario, @TokenHash = @TokenHash, @Crear = 0, @Bloquear = 0, @IDCarrito = @IDCarrito OUTPUT;

    SELECT  @IDCarrito AS IDCarrito,
            t.Subtotal, t.Descuento, t.Total, t.BaseImponible, t.Iva, t.Lineas,
            cu.IDCupon,
            cu.Codigo AS CodigoCupon,
            t.CuponRechazo,
            CASE WHEN t.CuponRechazo = N'MINIMO_NO_ALCANZADO'
                 THEN CONCAT(N'La compra m�nima para este cup�n es Q', CONVERT(NVARCHAR(30), cu.MontoMinimo), N'.')
                 ELSE m.Mensaje END AS CuponMensaje
    FROM    dbo.FU_Carrito_Totales(@IDCarrito) t
    LEFT JOIN dbo.Cupones cu ON cu.IDCupon = t.IDCupon
    OUTER APPLY dbo.FU_Cupones_MensajeRechazo(t.CuponRechazo) m;

    SELECT  d.IDVariante,
            v.SKU,
            p.IDProducto,
            p.Nombre AS Producto,
            (SELECT STRING_AGG(CONCAT(a.Nombre, N': ', va.Valor), N', ') WITHIN GROUP (ORDER BY a.Nombre)
             FROM dbo.VarianteAtributos va
             JOIN dbo.Atributos a ON a.IDAtributo = va.IDAtributo
             WHERE va.IDVariante = v.IDVariante) AS Atributos,
            v.Precio,
            d.Cantidad,
            CAST(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio AS DECIMAL(18,2)) AS Subtotal,
            v.ExistenciaDisponible AS Disponible,
            CAST(CASE WHEN v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1 THEN 1 ELSE 0 END AS BIT) AS Vendible,
            CAST(CASE WHEN d.Cantidad > v.ExistenciaDisponible THEN 1 ELSE 0 END AS BIT)            AS ExcedeExistencia,
            i.Url AS ImagenPrincipal
    FROM    dbo.CarritosDetalle d
    JOIN    dbo.Variantes v  ON v.IDVariante = d.IDVariante
    JOIN    dbo.Productos p  ON p.IDProducto = v.IDProducto
    JOIN    dbo.Categorias c ON c.IDCategoria = p.IDCategoria
    LEFT JOIN dbo.ImagenesProducto i ON i.IDProducto = p.IDProducto AND i.EsPrincipal = 1
    WHERE   d.IDCarrito = @IDCarrito
    ORDER BY d.FechaCreacion, d.IDVariante;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'016_Cupones_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'016_Cupones_Procedimientos.sql');
GO
/*CheckOUT*/
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
        THROW 50053, N'Destinatario, tel�fono, departamento, municipio y direcci�n son obligatorios.', 1;

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
        THROW 50053, N'Destinatario, tel�fono, departamento, municipio y direcci�n son obligatorios.', 1;

    DECLARE @Existe INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Existe = IDDireccion
        FROM   dbo.Direcciones WITH (UPDLOCK, HOLDLOCK)
        WHERE  IDDireccion = @IDDireccion AND IDUsuario = @IDUsuario AND Activo = 1;

        IF @Existe IS NULL
            THROW 50100, N'La direcci�n no existe.', 1;

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
            THROW 50100, N'La direcci�n no existe.', 1;

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
        THROW 50053, N'La lista de productos a reservar no es un JSON v�lido.', 1;

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
        THROW 50053, N'La lista de productos a reservar est� vac�a.', 1;
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
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' no est� disponible para la venta.')
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
        THROW 50053, N'La clave de idempotencia debe tener de 8 a 64 caracteres (letras, n�meros, guion o guion bajo).', 1;

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
                THROW 50111, N'La clave de idempotencia ya se us� con datos distintos.', 1;

            IF @EstadoPago = N'INICIADO'
               AND NOT EXISTS (SELECT 1 FROM dbo.Reservas
                               WHERE IDReserva = @IDReservaPago AND Estado = N'ACTIVA' AND FechaVencimiento > SYSUTCDATETIME())
            BEGIN
                UPDATE dbo.Pagos
                SET    Estado = N'EXPIRADO', Motivo = N'La reserva venci� antes de completar el pago.',
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
            THROW 50100, N'La direcci�n de entrega no existe.', 1;

        SELECT @CostoEnvio = Costo
        FROM   dbo.MetodosEnvio
        WHERE  IDMetodoEnvio = @IDMetodoEnvio AND Activo = 1;

        IF @CostoEnvio IS NULL
            THROW 50101, N'El m�todo de env�o no es v�lido.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.CarritosDetalle WHERE IDCarrito = @IDCarrito)
            THROW 50102, N'El carrito est� vac�o.', 1;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' ya no est� disponible para la venta.')
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
            SET @Mensaje = CONCAT(N'El total cambi� a Q', CONVERT(NVARCHAR(30), @Total), N'. Revise su pedido antes de pagar.');
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
            THROW 50112, N'Ya hay una solicitud de pago id�ntica en proceso.', 1;
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
        THROW 50053, N'La clave de idempotencia no es v�lida.', 1;

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
            THROW 50114, N'El carrito cambi� antes de confirmar el pago.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Reservas
                       WHERE IDReserva = @IDReserva AND Estado = N'ACTIVA' AND FechaVencimiento > SYSUTCDATETIME())
            THROW 50114, N'La reserva de existencias venci� antes de confirmar el pago.', 1;

        SELECT  @Subtotal = t.Subtotal, @Descuento = t.Descuento, @CuponRechazo = t.CuponRechazo
        FROM    dbo.FU_Carrito_Totales(@IDCarrito) t;

        SELECT  @CostoEnvio = Costo, @NombreEnvio = Nombre
        FROM    dbo.MetodosEnvio
        WHERE   IDMetodoEnvio = @IDMetodoEnvio;

        IF @CuponRechazo IS NOT NULL
            THROW 50114, N'El cup�n dej� de ser aplicable antes de confirmar el pago.', 1;

        SET @Total = @Subtotal - @Descuento + @CostoEnvio;

        IF @Total <> @MontoPago
            THROW 50114, N'El total cambi� despu�s de iniciar el pago (precios o costo de env�o).', 1;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'El producto con SKU ', v.SKU, N' dej� de estar disponible para la venta.')
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
            THROW 50114, N'La direcci�n de entrega ya no est� disponible.', 1;

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
        THROW 50053, N'La clave de idempotencia no es v�lida.', 1;

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
/*Pedidos*/
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
            SET @Mensaje = CONCAT(N'Transici�n no permitida: de ', @EstadoActual, N' a ', @EstadoNuevo, N'.');
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
        THROW 50121, N'Este SP solo avanza a EN_PREPARACION, DESPACHADO o ENTREGADO; para cancelar o devolver use la operaci�n correspondiente.', 1;

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
            THROW 50122, N'Solo puede cancelar su pedido mientras est� PAGADO; si ya se est� preparando, contacte a la tienda.', 1;

        EXEC Interno.SP_Pedidos_CambiarEstado
            @IDPedido = @IDPedido, @EstadoNuevo = N'CANCELADO', @IDUsuario = @IDUsuarioActor,
            @Comentario = @Motivo;

        SET @MotivoKardex = CONCAT(N'Cancelaci�n del pedido ', @Numero, N': ', LEFT(@Motivo, 180));

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
        THROW 50125, N'Indique las l�neas a devolver o solicite la devoluci�n total.', 1;

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
            THROW 50125, N'La lista de l�neas a devolver est� vac�a.', 1;
        IF EXISTS (SELECT 1 FROM @Crudo WHERE IDDetallePedido IS NULL OR Cantidad IS NULL OR Cantidad <= 0)
            THROW 50125, N'Cada l�nea requiere idDetallePedido y una cantidad mayor a cero.', 1;

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
            THROW 50125, N'Alguna de las l�neas no pertenece al pedido.', 1;

        INSERT INTO @Calculo (IDDetallePedido, IDVariante, SKU, Cantidad, PrecioUnitario, CantidadVendida, DescuentoLinea, Devuelta)
        SELECT  d.IDDetallePedido, d.IDVariante, d.SKU, s.Cantidad, d.PrecioUnitario, d.Cantidad, d.DescuentoLinea, d.CantidadDevuelta
        FROM    @Solicitud s
        JOIN    dbo.DetallePedidos d WITH (UPDLOCK, HOLDLOCK) ON d.IDDetallePedido = s.IDDetallePedido;

        SET @Falla = NULL;
        SELECT TOP (1) @Falla = CONCAT(N'No se puede devolver m�s de lo vendido en la l�nea del SKU ', SKU,
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

        SET @MotivoKardex = CONCAT(N'Devoluci�n del pedido ', @Numero, N': ', LEFT(@Motivo, 180));

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
        SET @Comentario = CONCAT(N'Devoluci�n #', @IDDevolucion, N': ', LEFT(@Motivo, 200));

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
           p.Motivo = N'La reserva venci� antes de completar el pago.',
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
/*Dashboard*/
CREATE OR ALTER PROCEDURE Interno.SP_Reportes_ResolverRango
    @FechaDesde DATE          OUTPUT,
    @FechaHasta DATE          OUTPUT,
    @DesdeUtc   DATETIME2(0)  OUTPUT,
    @HastaUtc   DATETIME2(0)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                                  WHERE Clave = N'OffsetHorasLocal'), -6);

    IF @FechaHasta IS NULL SET @FechaHasta = CAST(DATEADD(HOUR, @Offset, SYSUTCDATETIME()) AS DATE);
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(DAY, -29, @FechaHasta);

    IF @FechaDesde > @FechaHasta OR DATEDIFF(DAY, @FechaDesde, @FechaHasta) > 730
        THROW 50130, N'El rango de fechas no es v�lido: la fecha inicial no puede ser posterior a la final y el m�ximo es de 2 a�os.', 1;

    SET @DesdeUtc = DATEADD(HOUR, -@Offset, CAST(@FechaDesde AS DATETIME2(0)));
    SET @HastaUtc = DATEADD(HOUR, -@Offset, CAST(DATEADD(DAY, 1, @FechaHasta) AS DATETIME2(0)));
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Reportes_ResumenDashboard
    @IDUsuarioActor INT,
    @FechaDesde     DATE = NULL,
    @FechaHasta     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0), @Dias INT, @DesdePrevUtc DATETIME2(0);

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    SET @Dias = DATEDIFF(DAY, @FechaDesde, @FechaHasta) + 1;
    SET @DesdePrevUtc = DATEADD(DAY, -@Dias, @DesdeUtc);

    SELECT  @FechaDesde AS FechaDesde,
            @FechaHasta AS FechaHasta,
            a.Pedidos,
            a.VentasBrutas,
            a.Devoluciones,
            a.VentasNetas,
            CAST(CASE WHEN a.Pedidos = 0 THEN 0 ELSE ROUND(a.VentasNetas / a.Pedidos, 2) END AS DECIMAL(18,2)) AS TicketPromedio,
            u.UnidadesNetas,
            c.PedidosCancelados,
            c.MontoCancelado,
            p.PedidosAnterior,
            p.VentasNetasAnterior,
            ab.CarritosAbandonados,
            ab.ValorCarritosAbandonados
    FROM   (SELECT  COUNT(*)                         AS Pedidos,
                    ISNULL(SUM(Total), 0)            AS VentasBrutas,
                    ISNULL(SUM(Devuelto), 0)         AS Devoluciones,
                    ISNULL(SUM(VentaNeta), 0)        AS VentasNetas
            FROM    dbo.VW_Dashboard_VentasPorPedido
            WHERE   FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc) a
    CROSS JOIN (SELECT ISNULL(SUM(UnidadesNetas), 0) AS UnidadesNetas
                FROM   dbo.VW_Dashboard_VentasPorLinea
                WHERE  FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc) u
    CROSS JOIN (SELECT COUNT(*) AS PedidosCancelados, ISNULL(SUM(Total), 0) AS MontoCancelado
                FROM   dbo.Pedidos
                WHERE  Estado = N'CANCELADO' AND FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc) c
    CROSS JOIN (SELECT COUNT(*) AS PedidosAnterior, ISNULL(SUM(VentaNeta), 0) AS VentasNetasAnterior
                FROM   dbo.VW_Dashboard_VentasPorPedido
                WHERE  FechaCreacion >= @DesdePrevUtc AND FechaCreacion < @DesdeUtc) p
    CROSS JOIN (SELECT COUNT(*) AS CarritosAbandonados, ISNULL(SUM(Valor), 0) AS ValorCarritosAbandonados
                FROM   dbo.VW_Dashboard_CarritosAbandonados) ab;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Reportes_VentasPorPeriodo
    @IDUsuarioActor INT,
    @FechaDesde     DATE         = NULL,
    @FechaHasta     DATE         = NULL,
    @Agrupacion     NVARCHAR(10) = N'DIA'
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    SET @Agrupacion = UPPER(LTRIM(RTRIM(ISNULL(@Agrupacion, N'DIA'))));
    IF @Agrupacion NOT IN (N'DIA', N'SEMANA', N'MES')
        THROW 50053, N'La agrupaci�n debe ser DIA, SEMANA o MES.', 1;

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0);
    DECLARE @Base DATE = '19000101'; 

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    ;WITH Dias AS (
        SELECT TOP (DATEDIFF(DAY, @FechaDesde, @FechaHasta) + 1)
               DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @FechaDesde) AS Dia
        FROM   sys.all_objects a CROSS JOIN sys.all_objects b
    ),
    Periodos AS (
        SELECT DISTINCT
               CASE @Agrupacion
                    WHEN N'DIA'    THEN Dia
                    WHEN N'SEMANA' THEN DATEADD(DAY, -(DATEDIFF(DAY, @Base, Dia) % 7), Dia)
                    ELSE DATEFROMPARTS(YEAR(Dia), MONTH(Dia), 1)
               END AS Inicio
        FROM   Dias
    ),
    Ventas AS (
        SELECT  x.Inicio,
                COUNT(*)          AS Pedidos,
                SUM(x.Total)      AS VentasBrutas,
                SUM(x.Devuelto)   AS Devoluciones,
                SUM(x.VentaNeta)  AS VentasNetas
        FROM (
            SELECT  CASE @Agrupacion
                         WHEN N'DIA'    THEN FechaLocal
                         WHEN N'SEMANA' THEN DATEADD(DAY, -(DATEDIFF(DAY, @Base, FechaLocal) % 7), FechaLocal)
                         ELSE DATEFROMPARTS(YEAR(FechaLocal), MONTH(FechaLocal), 1)
                    END AS Inicio,
                    Total, Devuelto, VentaNeta
            FROM    dbo.VW_Dashboard_VentasPorPedido
            WHERE   FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc
        ) x
        GROUP BY x.Inicio
    )
    SELECT  p.Inicio AS PeriodoInicio,
            CASE @Agrupacion
                 WHEN N'DIA'    THEN CONVERT(NVARCHAR(10), p.Inicio, 23)
                 WHEN N'SEMANA' THEN CONCAT(N'Sem ', CONVERT(NVARCHAR(10), p.Inicio, 23))
                 ELSE LEFT(CONVERT(NVARCHAR(10), p.Inicio, 23), 7)
            END AS Etiqueta,
            ISNULL(v.Pedidos, 0)       AS Pedidos,
            ISNULL(v.VentasBrutas, 0)  AS VentasBrutas,
            ISNULL(v.Devoluciones, 0)  AS Devoluciones,
            ISNULL(v.VentasNetas, 0)   AS VentasNetas,
            CAST(CASE WHEN ISNULL(v.Pedidos, 0) = 0 THEN 0
                      ELSE ROUND(v.VentasNetas / v.Pedidos, 2) END AS DECIMAL(18,2)) AS TicketPromedio
    FROM    Periodos p
    LEFT JOIN Ventas v ON v.Inicio = p.Inicio
    ORDER BY p.Inicio;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Reportes_VentasPorCategoria
    @IDUsuarioActor INT,
    @FechaDesde     DATE = NULL,
    @FechaHasta     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0);

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    SELECT  l.IDCategoria,
            l.Categoria,
            SUM(l.UnidadesNetas)           AS Unidades,
            SUM(l.VentaNeta)               AS VentasNetas,
            COUNT(DISTINCT l.IDPedido)     AS Pedidos,
            CAST(ROUND(100.0 * SUM(l.VentaNeta) / NULLIF(SUM(SUM(l.VentaNeta)) OVER (), 0), 2) AS DECIMAL(5,2)) AS Porcentaje
    FROM    dbo.VW_Dashboard_VentasPorLinea l
    WHERE   l.FechaCreacion >= @DesdeUtc AND l.FechaCreacion < @HastaUtc
    GROUP BY l.IDCategoria, l.Categoria
    HAVING  SUM(l.UnidadesNetas) > 0
    ORDER BY SUM(l.VentaNeta) DESC, l.IDCategoria;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Reportes_TopProductos
    @IDUsuarioActor INT,
    @FechaDesde     DATE         = NULL,
    @FechaHasta     DATE         = NULL,
    @Top            INT          = 10,
    @OrdenarPor     NVARCHAR(10) = N'UNIDADES' 
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    SET @OrdenarPor = UPPER(LTRIM(RTRIM(ISNULL(@OrdenarPor, N'UNIDADES'))));
    IF @OrdenarPor NOT IN (N'UNIDADES', N'VENTAS')
        THROW 50053, N'El orden debe ser UNIDADES o VENTAS.', 1;
    IF @Top IS NULL OR @Top < 1 SET @Top = 10;
    IF @Top > 50 SET @Top = 50;

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0);

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    ;WITH Agg AS (
        SELECT  l.IDProducto, l.Producto, l.Categoria,
                SUM(l.UnidadesNetas) AS Unidades,
                SUM(l.VentaNeta)     AS VentasNetas
        FROM    dbo.VW_Dashboard_VentasPorLinea l
        WHERE   l.FechaCreacion >= @DesdeUtc AND l.FechaCreacion < @HastaUtc
        GROUP BY l.IDProducto, l.Producto, l.Categoria
        HAVING  SUM(l.UnidadesNetas) > 0
    )
    SELECT TOP (@Top)
            ROW_NUMBER() OVER (ORDER BY CASE WHEN @OrdenarPor = N'VENTAS' THEN VentasNetas END DESC,
                                        Unidades DESC, IDProducto) AS Ranking,
            IDProducto, Producto, Categoria, Unidades, VentasNetas
    FROM    Agg
    ORDER BY Ranking;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Reportes_CarritosAbandonados
    @IDUsuarioActor INT,
    @OrdenarPor     NVARCHAR(20) = N'HorasInactivo', 
    @Direccion      NVARCHAR(4)  = N'DESC',
    @Pagina         INT          = 1,
    @TamanoPagina   INT          = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    SELECT  c.IDCarrito, c.Cliente, c.EsInvitado, c.Lineas, c.Unidades, c.Valor,
            c.FechaCreacion, c.FechaActualizacion, c.HorasInactivo,
            COUNT(*)      OVER () AS TotalRegistros,
            SUM(c.Valor)  OVER () AS ValorTotal
    FROM    dbo.VW_Dashboard_CarritosAbandonados c
    ORDER BY
        CASE WHEN @OrdenarPor = N'HorasInactivo' AND @Direccion = N'ASC'  THEN c.HorasInactivo END ASC,
        CASE WHEN @OrdenarPor = N'HorasInactivo' AND @Direccion = N'DESC' THEN c.HorasInactivo END DESC,
        CASE WHEN @OrdenarPor = N'Valor'         AND @Direccion = N'ASC'  THEN c.Valor         END ASC,
        CASE WHEN @OrdenarPor = N'Valor'         AND @Direccion = N'DESC' THEN c.Valor         END DESC,
        CASE WHEN @OrdenarPor = N'Unidades'      AND @Direccion = N'ASC'  THEN c.Unidades      END ASC,
        CASE WHEN @OrdenarPor = N'Unidades'      AND @Direccion = N'DESC' THEN c.Unidades      END DESC,
        c.IDCarrito
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_Listar
    @IDUsuarioActor INT,
    @Estado         NVARCHAR(20)  = NULL,
    @IDCliente      INT           = NULL,
    @Texto          NVARCHAR(100) = NULL,
    @FechaDesde     DATE          = NULL,
    @FechaHasta     DATE          = NULL,
    @OrdenarPor     NVARCHAR(20)  = N'Fecha',
    @Direccion      NVARCHAR(4)   = N'DESC',
    @Pagina         INT           = 1,
    @TamanoPagina   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Usuarios u
        JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
        JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
        WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1
          AND p.Codigo IN (N'PEDIDOS_GESTIONAR', N'REPORTES_VER'))
        THROW 50016, N'No tiene permisos para realizar esta acci�n.', 1;

    IF @FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL AND @FechaDesde > @FechaHasta
        THROW 50130, N'El rango de fechas no es v�lido: la fecha inicial no puede ser posterior a la final.', 1;

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    DECLARE @Offset INT = ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                                  WHERE Clave = N'OffsetHorasLocal'), -6);
    DECLARE @DesdeUtc DATETIME2(0) = NULL, @HastaUtc DATETIME2(0) = NULL;

    IF @FechaDesde IS NOT NULL
        SET @DesdeUtc = DATEADD(HOUR, -@Offset, CAST(@FechaDesde AS DATETIME2(0)));
    IF @FechaHasta IS NOT NULL
        SET @HastaUtc = DATEADD(HOUR, -@Offset, CAST(DATEADD(DAY, 1, @FechaHasta) AS DATETIME2(0)));

    DECLARE @Patron NVARCHAR(102) =
        CASE WHEN @Texto IS NULL OR LTRIM(RTRIM(@Texto)) = N'' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Texto)) + N'%' END;

    SELECT  h.IDPedido, h.NumeroPedido, h.Estado, h.IDUsuario, h.CorreoCliente, h.NombreCliente,
            h.Total, h.Devuelto, h.NombreEnvio, h.CodigoCupon, h.FechaCreacion, h.FechaActualizacion,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.VW_Pedidos_Historial h
    WHERE   (@Estado IS NULL OR h.Estado = @Estado)
        AND (@IDCliente IS NULL OR h.IDUsuario = @IDCliente)
        AND (@DesdeUtc IS NULL OR h.FechaCreacion >= @DesdeUtc)
        AND (@HastaUtc IS NULL OR h.FechaCreacion <  @HastaUtc)
        AND (@Patron IS NULL
             OR h.NumeroPedido  LIKE @Patron
             OR h.CorreoCliente LIKE @Patron
             OR h.NombreCliente LIKE @Patron)
    ORDER BY
        CASE WHEN @OrdenarPor = N'Fecha'   AND @Direccion = N'ASC'  THEN h.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'Fecha'   AND @Direccion = N'DESC' THEN h.FechaCreacion END DESC,
        CASE WHEN @OrdenarPor = N'Total'   AND @Direccion = N'ASC'  THEN h.Total         END ASC,
        CASE WHEN @OrdenarPor = N'Total'   AND @Direccion = N'DESC' THEN h.Total         END DESC,
        CASE WHEN @OrdenarPor = N'Estado'  AND @Direccion = N'ASC'  THEN h.Estado        END ASC,
        CASE WHEN @OrdenarPor = N'Estado'  AND @Direccion = N'DESC' THEN h.Estado        END DESC,
        CASE WHEN @OrdenarPor = N'Cliente' AND @Direccion = N'ASC'  THEN h.NombreCliente END ASC,
        CASE WHEN @OrdenarPor = N'Cliente' AND @Direccion = N'DESC' THEN h.NombreCliente END DESC,
        h.IDPedido DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Configuracion_Listar
    @IDUsuarioActor INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CONFIGURACION_GESTIONAR';

    SELECT Clave, Valor, Descripcion, FechaActualizacion
    FROM   dbo.Configuracion
    ORDER BY Clave;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Configuracion_Actualizar
    @IDUsuarioActor INT,
    @Clave          NVARCHAR(50),
    @Valor          NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CONFIGURACION_GESTIONAR';

    SET @Clave = LTRIM(RTRIM(@Clave));
    SET @Valor = LTRIM(RTRIM(@Valor));

    IF NOT EXISTS (SELECT 1 FROM dbo.Configuracion WHERE Clave = @Clave)
        THROW 50131, N'La clave de configuraci�n no existe.', 1;

    DECLARE @Entero INT = TRY_CAST(@Valor AS INT);

    IF @Clave = N'OffsetHorasLocal' AND (@Entero IS NULL OR @Entero NOT BETWEEN -12 AND 14)
        THROW 50132, N'OffsetHorasLocal debe ser un n�mero entero entre -12 y 14.', 1;
    IF @Clave = N'AbandonoCarritoHoras' AND (@Entero IS NULL OR @Entero NOT BETWEEN 1 AND 720)
        THROW 50132, N'AbandonoCarritoHoras debe ser un n�mero entero entre 1 y 720.', 1;

    SET @Valor = CAST(@Entero AS NVARCHAR(20));

    DECLARE @ValorActual NVARCHAR(100), @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ValorActual = Valor
        FROM   dbo.Configuracion WITH (UPDLOCK, HOLDLOCK)
        WHERE  Clave = @Clave;

        IF @ValorActual = @Valor
        BEGIN
            COMMIT TRANSACTION;
            SELECT @Clave AS Clave, @Valor AS Valor;
            RETURN;
        END;

        UPDATE dbo.Configuracion
        SET    Valor = @Valor, FechaActualizacion = SYSUTCDATETIME()
        WHERE  Clave = @Clave;

        SET @ValorAnterior = (SELECT @Clave AS Clave, @ValorActual AS Valor FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Clave AS Clave, @Valor       AS Valor FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Configuracion', @Entidad = N'Configuracion',
            @IDEntidad = NULL, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @Clave AS Clave, @Valor AS Valor;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'026_Reportes_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'026_Reportes_Procedimientos.sql');
GO