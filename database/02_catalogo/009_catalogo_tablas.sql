/* =============================================================================
   009_Catalogo_Tablas.sql
   Módulo 2 - Catálogo: Categorias, Productos, ImagenesProducto, Atributos,
   Variantes y VarianteAtributos.

   Reglas críticas protegidas en la base de datos:
     - SKU único, en mayúsculas y sin espacios.
     - Precio mayor a cero (DECIMAL, nunca FLOAT).
     - 0 <= ExistenciaReservada <= ExistenciaFisica  => nunca hay sobreventa.
   Las columnas de existencia solo las modifican los SP del módulo de inventario,
   siempre en la misma transacción que registran el movimiento del kardex.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

ALTER TABLE dbo.Bitacora DROP CONSTRAINT CK_Bitacora_Accion;
GO
ALTER TABLE dbo.Bitacora ADD CONSTRAINT CK_Bitacora_Accion
    CHECK (Accion IN (N'CREAR', N'MODIFICAR', N'DESACTIVAR', N'ELIMINAR', N'CAMBIO_ESTADO'));
GO

CREATE TABLE dbo.Categorias (
    IDCategoria        INT IDENTITY(1,1) CONSTRAINT PK_Categorias PRIMARY KEY,
    Nombre             NVARCHAR(100) NOT NULL CONSTRAINT UQ_Categorias_Nombre UNIQUE,
    Descripcion        NVARCHAR(255) NULL,
    Activo             BIT           NOT NULL CONSTRAINT DF_Categorias_Activo DEFAULT 1,
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Categorias_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Categorias_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Categorias_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
GO

CREATE TABLE dbo.Productos (
    IDProducto         INT IDENTITY(1,1) CONSTRAINT PK_Productos PRIMARY KEY,
    IDCategoria        INT           NOT NULL CONSTRAINT FK_Productos_Categorias REFERENCES dbo.Categorias (IDCategoria),
    Nombre             NVARCHAR(150) NOT NULL,
    Descripcion        NVARCHAR(MAX) NULL,
    Activo             BIT           NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT 1,
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Productos_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Productos_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Productos_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
CREATE INDEX IX_Productos_Categoria_Activo ON dbo.Productos (IDCategoria, Activo) INCLUDE (Nombre, FechaCreacion);
CREATE INDEX IX_Productos_Nombre ON dbo.Productos (Nombre);
GO


CREATE TABLE dbo.ImagenesProducto (
    IDImagenProducto INT IDENTITY(1,1) CONSTRAINT PK_ImagenesProducto PRIMARY KEY,
    IDProducto       INT           NOT NULL CONSTRAINT FK_ImagenesProducto_Productos REFERENCES dbo.Productos (IDProducto),
    Url              NVARCHAR(500) NOT NULL,
    Orden            INT           NOT NULL CONSTRAINT DF_ImagenesProducto_Orden DEFAULT 0,
    EsPrincipal      BIT           NOT NULL CONSTRAINT DF_ImagenesProducto_EsPrincipal DEFAULT 0,
    FechaCreacion    DATETIME2(0)  NOT NULL CONSTRAINT DF_ImagenesProducto_FechaCreacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_ImagenesProducto_Url CHECK (Url LIKE N'https://%' OR Url LIKE N'http://%' OR Url LIKE N'/%')
);
CREATE INDEX IX_ImagenesProducto_IDProducto ON dbo.ImagenesProducto (IDProducto, Orden);
CREATE UNIQUE INDEX UX_ImagenesProducto_Principal ON dbo.ImagenesProducto (IDProducto) WHERE EsPrincipal = 1;
GO

CREATE TABLE dbo.Atributos (
    IDAtributo    INT IDENTITY(1,1) CONSTRAINT PK_Atributos PRIMARY KEY,
    Nombre        NVARCHAR(50) NOT NULL CONSTRAINT UQ_Atributos_Nombre UNIQUE,
    Activo        BIT          NOT NULL CONSTRAINT DF_Atributos_Activo DEFAULT 1,
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Atributos_FechaCreacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Atributos_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
GO

CREATE TABLE dbo.Variantes (
    IDVariante           INT IDENTITY(1,1) CONSTRAINT PK_Variantes PRIMARY KEY,
    IDProducto           INT           NOT NULL CONSTRAINT FK_Variantes_Productos REFERENCES dbo.Productos (IDProducto),
    SKU                  NVARCHAR(50)  NOT NULL CONSTRAINT UQ_Variantes_SKU UNIQUE,
    Precio               DECIMAL(12,2) NOT NULL,
    ExistenciaFisica     INT           NOT NULL CONSTRAINT DF_Variantes_ExistenciaFisica DEFAULT 0,
    ExistenciaReservada  INT           NOT NULL CONSTRAINT DF_Variantes_ExistenciaReservada DEFAULT 0,
    ExistenciaDisponible AS (ExistenciaFisica - ExistenciaReservada) PERSISTED,
    Activo               BIT           NOT NULL CONSTRAINT DF_Variantes_Activo DEFAULT 1,
    FechaCreacion        DATETIME2(0)  NOT NULL CONSTRAINT DF_Variantes_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion   DATETIME2(0)  NOT NULL CONSTRAINT DF_Variantes_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Variantes_Precio CHECK (Precio > 0),
    CONSTRAINT CK_Variantes_SKU_Formato CHECK (
        CHARINDEX(N' ', SKU) = 0
        AND SKU COLLATE Latin1_General_100_BIN2 = UPPER(SKU) COLLATE Latin1_General_100_BIN2
    ),
    CONSTRAINT CK_Variantes_Existencias CHECK (
        ExistenciaFisica >= 0
        AND ExistenciaReservada >= 0
        AND ExistenciaReservada <= ExistenciaFisica
    )
);
CREATE INDEX IX_Variantes_Producto ON dbo.Variantes (IDProducto, Activo) INCLUDE (Precio, ExistenciaDisponible);
GO

CREATE TABLE dbo.VarianteAtributos (
    IDVariante INT NOT NULL CONSTRAINT FK_VarianteAtributos_Variantes REFERENCES dbo.Variantes (IDVariante),
    IDAtributo INT NOT NULL CONSTRAINT FK_VarianteAtributos_Atributos REFERENCES dbo.Atributos (IDAtributo),
    Valor      NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_VarianteAtributos PRIMARY KEY (IDVariante, IDAtributo),
    CONSTRAINT CK_VarianteAtributos_Valor CHECK (LEN(LTRIM(RTRIM(Valor))) > 0)
);
CREATE INDEX IX_VarianteAtributos_Atributo_Valor ON dbo.VarianteAtributos (IDAtributo, Valor);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'007_Catalogo_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'007_Catalogo_Tablas.sql');
GO