/* =============================================================================
   001_Crear_Tablas.sql
   Módulo 1 - Seguridad: Roles, Permisos, RolesPermisos, Usuarios,
   TokensRefresco y Bitacora.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE TABLE dbo.VersionesEsquema (
    IDVersionEsquema INT IDENTITY(1,1) CONSTRAINT PK_VersionesEsquema PRIMARY KEY,
    Script           NVARCHAR(100) NOT NULL CONSTRAINT UQ_VersionesEsquema_Script UNIQUE,
    FechaAplicacion  DATETIME2(0)  NOT NULL CONSTRAINT DF_VersionesEsquema_FechaAplicacion DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.Roles (
    IDRol              INT IDENTITY(1,1) CONSTRAINT PK_Roles PRIMARY KEY,
    Nombre             NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Roles_Nombre UNIQUE,
    Descripcion        NVARCHAR(255) NOT NULL,
    Activo             BIT           NOT NULL CONSTRAINT DF_Roles_Activo DEFAULT 1,
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Roles_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Roles_FechaActualizacion DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.Permisos (
    IDPermiso     INT IDENTITY(1,1) CONSTRAINT PK_Permisos PRIMARY KEY,
    Codigo        NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Permisos_Codigo UNIQUE,
    Descripcion   NVARCHAR(255) NOT NULL,
    FechaCreacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Permisos_FechaCreacion DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE dbo.RolesPermisos (
    IDRol     INT NOT NULL CONSTRAINT FK_RolesPermisos_Roles    REFERENCES dbo.Roles (IDRol),
    IDPermiso INT NOT NULL CONSTRAINT FK_RolesPermisos_Permisos REFERENCES dbo.Permisos (IDPermiso),
    CONSTRAINT PK_RolesPermisos PRIMARY KEY (IDRol, IDPermiso)
);
CREATE INDEX IX_RolesPermisos_IDPermiso ON dbo.RolesPermisos (IDPermiso);
GO

CREATE TABLE dbo.Usuarios (
    IDUsuario          INT IDENTITY(1,1) CONSTRAINT PK_Usuarios PRIMARY KEY,
    IDRol              INT           NOT NULL CONSTRAINT FK_Usuarios_Roles REFERENCES dbo.Roles (IDRol),
    Correo             NVARCHAR(255) NOT NULL CONSTRAINT UQ_Usuarios_Correo UNIQUE,
    PasswordHash       NVARCHAR(255) NOT NULL,
    Nombres            NVARCHAR(100) NOT NULL,
    Apellidos          NVARCHAR(100) NOT NULL,
    Telefono           NVARCHAR(20)  NULL,
    Activo             BIT           NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT 1,
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Usuarios_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Usuarios_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Usuarios_Correo    CHECK (Correo LIKE N'_%@_%._%'),
    CONSTRAINT CK_Usuarios_Nombres   CHECK (LEN(LTRIM(RTRIM(Nombres))) > 0),
    CONSTRAINT CK_Usuarios_Apellidos CHECK (LEN(LTRIM(RTRIM(Apellidos))) > 0)
);
CREATE INDEX IX_Usuarios_IDRol ON dbo.Usuarios (IDRol);
GO

CREATE TABLE dbo.TokensRefresco (
    IDTokenRefresco  BIGINT IDENTITY(1,1) CONSTRAINT PK_TokensRefresco PRIMARY KEY,
    IDUsuario        INT      NOT NULL CONSTRAINT FK_TokensRefresco_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    TokenHash        CHAR(64) NOT NULL CONSTRAINT UQ_TokensRefresco_TokenHash UNIQUE,
    FechaCreacion    DATETIME2(0) NOT NULL CONSTRAINT DF_TokensRefresco_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaExpiracion  DATETIME2(0) NOT NULL,
    FechaRevocacion  DATETIME2(0) NULL,
    IDTokenReemplazo BIGINT NULL CONSTRAINT FK_TokensRefresco_Reemplazo REFERENCES dbo.TokensRefresco (IDTokenRefresco),
    CONSTRAINT CK_TokensRefresco_Expiracion CHECK (FechaExpiracion > FechaCreacion)
);
CREATE INDEX IX_TokensRefresco_IDUsuario ON dbo.TokensRefresco (IDUsuario);
GO