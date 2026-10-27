/* =============================================================================
   004_CrearProcedimientosAlmacenados.sql
   Módulo 1 - Seguridad: Roles, Permisos, RolesPermisos, Usuarios y
   TokensRefresco

    Códigos de error personalizados (THROW):
     50001 Configuración inválida (rol inexistente)       -> 500
     50010 Correo ya registrado                           -> 409
     50011 Rol no permitido para esta operación           -> 400
     50012 Usuario no encontrado                          -> 404
     50013 Usuario inexistente o inactivo                 -> 401/403
     50014 No puede desactivarse a sí mismo               -> 409
     50015 No se puede desactivar al último administrador -> 409
     50016 Sin permisos para la acción                    -> 403
     50020 Token de refresco inválido, expirado o revocado-> 401
     50021 Reutilización de token detectada               -> 401
     50030 La bitácora es inmutable                       -> 500
     50031 Los usuarios no se eliminan                    -> 500
   Los errores 2601/2627 (UNIQUE) se traducen a 50010 donde aplica.
   ============================================================================= */

USE ShopCart;
GO
SET NOCOUNT ON;
GO

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
        THROW 50016, N'No tiene permisos para realizar esta acción.', 1;
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
        THROW 50001, N'El rol Cliente no está configurado.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Usuarios WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo)
            THROW 50010, N'El correo ya está registrado.', 1;

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
            THROW 50010, N'El correo ya está registrado.', 1;
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
        THROW 50001, N'El rol solicitado no está configurado.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM dbo.Usuarios WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo)
            THROW 50010, N'El correo ya está registrado.', 1;

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
            THROW 50010, N'El correo ya está registrado.', 1;
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
                    THROW 50015, N'No se puede desactivar al último administrador activo.', 1;
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
        THROW 50013, N'El usuario no existe o está inactivo.', 1;

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
            THROW 50020, N'El token de refresco no es válido.', 1;

        IF @FechaRevocacion IS NOT NULL
        BEGIN
            UPDATE dbo.TokensRefresco
            SET    FechaRevocacion = SYSUTCDATETIME()
            WHERE  IDUsuario = @IDUsuario
              AND  FechaRevocacion IS NULL;

            COMMIT TRANSACTION;

            THROW 50021, N'Se detectó la reutilización de un token de refresco; se cerraron todas las sesiones.', 1;
        END;

        IF @FechaExpiracion <= SYSUTCDATETIME() OR @UsuarioActivo = 0
            THROW 50020, N'El token de refresco no es válido.', 1;

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