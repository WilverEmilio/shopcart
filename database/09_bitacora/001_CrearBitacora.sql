/* ---------------------------------------------------------------------------
   001_CrearBitacora.sql
   Módulo 9 - Bitácora
   --------------------------------------------------------------------------- */
use ShopCart;

CREATE TABLE dbo.Bitacora (
    IDBitacora    BIGINT IDENTITY(1,1) CONSTRAINT PK_Bitacora PRIMARY KEY,
    IDUsuario     INT           NULL CONSTRAINT FK_Bitacora_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    Modulo        NVARCHAR(50)  NOT NULL,
    Entidad       NVARCHAR(50)  NOT NULL,
    IDEntidad     BIGINT        NULL,
    Accion        NVARCHAR(20)  NOT NULL,
    ValorAnterior NVARCHAR(MAX) NULL,
    ValorNuevo    NVARCHAR(MAX) NULL,
    Fecha         DATETIME2(0)  NOT NULL CONSTRAINT DF_Bitacora_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Bitacora_Accion        CHECK (Accion IN (N'CREAR', N'MODIFICAR', N'DESACTIVAR', N'CAMBIO_ESTADO')),
    CONSTRAINT CK_Bitacora_ValorAnterior CHECK (ISJSON(ValorAnterior) = 1),
    CONSTRAINT CK_Bitacora_ValorNuevo    CHECK (ISJSON(ValorNuevo) = 1)
);
CREATE INDEX IX_Bitacora_Modulo_Fecha ON dbo.Bitacora (Modulo, Fecha DESC);
CREATE INDEX IX_Bitacora_Entidad      ON dbo.Bitacora (Entidad, IDEntidad);
CREATE INDEX IX_Bitacora_IDUsuario    ON dbo.Bitacora (IDUsuario);
GO

 

 
INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'001_CrearBaseDatos.sql');
INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'002_Seguridad_Tablas.sql');
GO