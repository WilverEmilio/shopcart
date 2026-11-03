use ShopCart;
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

CREATE OR ALTER TRIGGER dbo.TR_Bitacora_Inmutable ON dbo.Bitacora
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50030, N'La bit�cora no puede modificarse ni eliminarse.', 1;
END;
GO 

 
INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'001_CrearBaseDatos.sql');
INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'002_Seguridad_Tablas.sql');
GO

CREATE OR ALTER TRIGGER dbo.TR_Usuarios_NoEliminar ON dbo.Usuarios
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50031, N'Los usuarios no se eliminan; deben desactivarse.', 1;
END;
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

IF SCHEMA_ID(N'Interno') IS NULL
    EXEC sys.sp_executesql N'CREATE SCHEMA Interno AUTHORIZATION dbo;';
GO

CREATE TABLE dbo.MovimientosInventario (
    IDMovimiento         BIGINT IDENTITY(1,1) CONSTRAINT PK_MovimientosInventario PRIMARY KEY,
    IDVariante           INT           NOT NULL CONSTRAINT FK_MovimientosInventario_Variantes REFERENCES dbo.Variantes (IDVariante),
    TipoMovimiento       NVARCHAR(20)  NOT NULL,
    Cantidad             INT           NOT NULL,
    ExistenciaResultante INT           NOT NULL,
    Motivo               NVARCHAR(255) NOT NULL,
    TipoReferencia       NVARCHAR(20)  NULL,
    IDReferencia         INT           NULL,
    IDUsuario            INT           NOT NULL CONSTRAINT FK_MovimientosInventario_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    Fecha                DATETIME2(0)  NOT NULL CONSTRAINT DF_MovimientosInventario_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_MovimientosInventario_Tipo CHECK (TipoMovimiento IN (N'ENTRADA', N'SALIDA', N'AJUSTE', N'DEVOLUCION', N'CANCELACION')),
    CONSTRAINT CK_MovimientosInventario_Cantidad CHECK (
           (TipoMovimiento IN (N'ENTRADA', N'DEVOLUCION', N'CANCELACION') AND Cantidad > 0)
        OR (TipoMovimiento = N'SALIDA' AND Cantidad < 0)
        OR (TipoMovimiento = N'AJUSTE' AND Cantidad <> 0)
    ),
    CONSTRAINT CK_MovimientosInventario_Resultante CHECK (ExistenciaResultante >= 0),
    CONSTRAINT CK_MovimientosInventario_Motivo CHECK (LEN(LTRIM(RTRIM(Motivo))) > 0),
    CONSTRAINT CK_MovimientosInventario_TipoReferencia CHECK (TipoReferencia IS NULL OR TipoReferencia IN (N'PEDIDO', N'DEVOLUCION')),
    CONSTRAINT CK_MovimientosInventario_Referencia CHECK (
           (TipoReferencia IS NULL AND IDReferencia IS NULL)
        OR (TipoReferencia IS NOT NULL AND IDReferencia IS NOT NULL)
    )
);
CREATE INDEX IX_MovimientosInventario_Variante ON dbo.MovimientosInventario (IDVariante, IDMovimiento) INCLUDE (Cantidad, ExistenciaResultante);
CREATE INDEX IX_MovimientosInventario_Fecha ON dbo.MovimientosInventario (Fecha DESC, IDMovimiento DESC);
CREATE INDEX IX_MovimientosInventario_Usuario ON dbo.MovimientosInventario (IDUsuario);

CREATE UNIQUE INDEX UX_MovimientosInventario_Referencia
    ON dbo.MovimientosInventario (TipoMovimiento, TipoReferencia, IDReferencia, IDVariante)
    WHERE TipoReferencia IS NOT NULL;
GO

CREATE OR ALTER TRIGGER dbo.TR_MovimientosInventario_Inmutable ON dbo.MovimientosInventario
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50060, N'El kardex no puede modificarse ni eliminarse; corrija con un movimiento de ajuste.', 1;
END;
GO

CREATE TABLE dbo.Reservas (
    IDReserva        INT IDENTITY(1,1) CONSTRAINT PK_Reservas PRIMARY KEY,
    IDUsuario        INT          NOT NULL CONSTRAINT FK_Reservas_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    Estado           NVARCHAR(12) NOT NULL CONSTRAINT DF_Reservas_Estado DEFAULT N'ACTIVA',
    FechaCreacion    DATETIME2(0) NOT NULL CONSTRAINT DF_Reservas_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaVencimiento DATETIME2(0) NOT NULL,
    FechaCierre      DATETIME2(0) NULL,
    CONSTRAINT CK_Reservas_Estado CHECK (Estado IN (N'ACTIVA', N'CONSUMIDA', N'LIBERADA', N'VENCIDA')),
    CONSTRAINT CK_Reservas_Vencimiento CHECK (FechaVencimiento > FechaCreacion),
    CONSTRAINT CK_Reservas_Cierre CHECK (
           (Estado = N'ACTIVA' AND FechaCierre IS NULL)
        OR (Estado <> N'ACTIVA' AND FechaCierre IS NOT NULL)
    )
);
CREATE INDEX IX_Reservas_Estado_Vencimiento ON dbo.Reservas (Estado, FechaVencimiento);

CREATE UNIQUE INDEX UX_Reservas_UsuarioActiva ON dbo.Reservas (IDUsuario) WHERE Estado = N'ACTIVA';
GO

CREATE TABLE dbo.ReservasDetalle (
    IDReserva  INT NOT NULL CONSTRAINT FK_ReservasDetalle_Reservas  REFERENCES dbo.Reservas (IDReserva),
    IDVariante INT NOT NULL CONSTRAINT FK_ReservasDetalle_Variantes REFERENCES dbo.Variantes (IDVariante),
    Cantidad   INT NOT NULL,
    CONSTRAINT PK_ReservasDetalle PRIMARY KEY (IDReserva, IDVariante),
    CONSTRAINT CK_ReservasDetalle_Cantidad CHECK (Cantidad > 0)
);
CREATE INDEX IX_ReservasDetalle_Variante ON dbo.ReservasDetalle (IDVariante);
GO


CREATE OR ALTER VIEW dbo.VW_Inventario_Conciliacion
AS
SELECT  v.IDVariante,
        v.SKU,
        v.ExistenciaFisica,
        ISNULL(k.Total, 0)                        AS SumaKardex,
        v.ExistenciaFisica - ISNULL(k.Total, 0)   AS DiferenciaFisica,
        v.ExistenciaReservada,
        ISNULL(rs.Total, 0)                       AS SumaReservasActivas,
        v.ExistenciaReservada - ISNULL(rs.Total, 0) AS DiferenciaReservada
FROM    dbo.Variantes v
LEFT JOIN (
        SELECT IDVariante, SUM(Cantidad) AS Total
        FROM   dbo.MovimientosInventario
        GROUP BY IDVariante
) k ON k.IDVariante = v.IDVariante
LEFT JOIN (
        SELECT d.IDVariante, SUM(d.Cantidad) AS Total
        FROM   dbo.ReservasDetalle d
        JOIN   dbo.Reservas r ON r.IDReserva = d.IDReserva
        WHERE  r.Estado = N'ACTIVA'
        GROUP BY d.IDVariante
) rs ON rs.IDVariante = v.IDVariante;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'010_Inventario_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'010_Inventario_Tablas.sql');
GO

CREATE TABLE dbo.Carritos (
    IDCarrito          INT IDENTITY(1,1) CONSTRAINT PK_Carritos PRIMARY KEY,
    IDUsuario          INT          NULL CONSTRAINT FK_Carritos_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    TokenHash          CHAR(64)     NULL,
    Estado             NVARCHAR(12) NOT NULL CONSTRAINT DF_Carritos_Estado DEFAULT N'ACTIVO',
    FechaCreacion      DATETIME2(0) NOT NULL CONSTRAINT DF_Carritos_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0) NOT NULL CONSTRAINT DF_Carritos_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Carritos_Estado CHECK (Estado IN (N'ACTIVO', N'CONVERTIDO', N'FUSIONADO')),
    CONSTRAINT CK_Carritos_Propietario CHECK (
           (IDUsuario IS NOT NULL AND TokenHash IS NULL)
        OR (IDUsuario IS NULL AND TokenHash IS NOT NULL)
    ),
    CONSTRAINT CK_Carritos_TokenHash CHECK (TokenHash IS NULL OR TokenHash NOT LIKE N'%[^0-9a-f]%')
);

CREATE UNIQUE INDEX UX_Carritos_UsuarioActivo ON dbo.Carritos (IDUsuario)
    WHERE Estado = N'ACTIVO' AND IDUsuario IS NOT NULL;

CREATE UNIQUE INDEX UX_Carritos_TokenHash ON dbo.Carritos (TokenHash)
    WHERE TokenHash IS NOT NULL;
CREATE INDEX IX_Carritos_Usuario ON dbo.Carritos (IDUsuario) WHERE IDUsuario IS NOT NULL;
CREATE INDEX IX_Carritos_Estado_Actividad ON dbo.Carritos (Estado, FechaActualizacion);
GO

CREATE TABLE dbo.CarritosDetalle (
    IDCarrito     INT NOT NULL CONSTRAINT FK_CarritosDetalle_Carritos  REFERENCES dbo.Carritos (IDCarrito),
    IDVariante    INT NOT NULL CONSTRAINT FK_CarritosDetalle_Variantes REFERENCES dbo.Variantes (IDVariante),
    Cantidad      INT NOT NULL,
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_CarritosDetalle_FechaCreacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_CarritosDetalle PRIMARY KEY (IDCarrito, IDVariante),
    CONSTRAINT CK_CarritosDetalle_Cantidad CHECK (Cantidad > 0)
);
CREATE INDEX IX_CarritosDetalle_Variante ON dbo.CarritosDetalle (IDVariante);
GO

CREATE OR ALTER FUNCTION dbo.FU_Carrito_Totales (@IDCarrito INT)
RETURNS TABLE
AS
RETURN (
    SELECT  x.Subtotal,
            x.Descuento,
            x.Total,
            CAST(ROUND(x.Total / 1.12, 2) AS DECIMAL(18,2))              AS BaseImponible,
            CAST(x.Total - ROUND(x.Total / 1.12, 2) AS DECIMAL(18,2))    AS Iva,
            x.Lineas
    FROM (
        SELECT  CAST(ISNULL(SUM(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio), 0) AS DECIMAL(18,2)) AS Subtotal,
                CAST(0 AS DECIMAL(18,2))                                                            AS Descuento,
                CAST(ISNULL(SUM(CAST(d.Cantidad AS DECIMAL(18,2)) * v.Precio), 0) AS DECIMAL(18,2)) AS Total,
                COUNT(d.IDVariante)                                                                 AS Lineas
        FROM    dbo.CarritosDetalle d
        JOIN    dbo.Variantes v   ON v.IDVariante = d.IDVariante
        JOIN    dbo.Productos p   ON p.IDProducto = v.IDProducto
        JOIN    dbo.Categorias c  ON c.IDCategoria = p.IDCategoria
        WHERE   d.IDCarrito = @IDCarrito
            AND v.Activo = 1 AND p.Activo = 1 AND c.Activo = 1
    ) x
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'013_Carrito_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'013_Carrito_Tablas.sql');
GO

CREATE TABLE dbo.Cupones (
    IDCupon              INT IDENTITY(1,1) CONSTRAINT PK_Cupones PRIMARY KEY,
    Codigo               NVARCHAR(30)  NOT NULL CONSTRAINT UQ_Cupones_Codigo UNIQUE,
    Descripcion          NVARCHAR(255) NULL,
    TipoDescuento        NVARCHAR(12)  NOT NULL,
    Valor                DECIMAL(12,2) NOT NULL,
    IDCategoria          INT           NULL CONSTRAINT FK_Cupones_Categorias REFERENCES dbo.Categorias (IDCategoria),
    MontoMinimo          DECIMAL(12,2) NOT NULL CONSTRAINT DF_Cupones_MontoMinimo DEFAULT 0,
    FechaInicio          DATETIME2(0)  NOT NULL,
    FechaFin             DATETIME2(0)  NOT NULL,
    LimiteUsosTotal      INT           NULL,
    LimiteUsosPorCliente INT           NULL,
    UsosActuales         INT           NOT NULL CONSTRAINT DF_Cupones_UsosActuales DEFAULT 0,
    Activo               BIT           NOT NULL CONSTRAINT DF_Cupones_Activo DEFAULT 1,
    FechaCreacion        DATETIME2(0)  NOT NULL CONSTRAINT DF_Cupones_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion   DATETIME2(0)  NOT NULL CONSTRAINT DF_Cupones_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Cupones_Codigo CHECK (
        LEN(Codigo) BETWEEN 3 AND 30
        AND Codigo COLLATE Latin1_General_100_BIN2 NOT LIKE N'%[^A-Z0-9_-]%'
    ),
    CONSTRAINT CK_Cupones_Tipo  CHECK (TipoDescuento IN (N'PORCENTAJE', N'MONTO_FIJO')),
    CONSTRAINT CK_Cupones_Valor CHECK (Valor > 0 AND (TipoDescuento = N'MONTO_FIJO' OR Valor <= 100)),
    CONSTRAINT CK_Cupones_MontoMinimo CHECK (MontoMinimo >= 0),
    CONSTRAINT CK_Cupones_Vigencia CHECK (FechaFin > FechaInicio),
    CONSTRAINT CK_Cupones_LimiteTotal CHECK (LimiteUsosTotal IS NULL OR LimiteUsosTotal > 0),
    CONSTRAINT CK_Cupones_LimiteCliente CHECK (LimiteUsosPorCliente IS NULL OR LimiteUsosPorCliente > 0),

    CONSTRAINT CK_Cupones_Usos CHECK (UsosActuales >= 0 AND (LimiteUsosTotal IS NULL OR UsosActuales <= LimiteUsosTotal))
);
CREATE INDEX IX_Cupones_Categoria ON dbo.Cupones (IDCategoria) WHERE IDCategoria IS NOT NULL;
GO

CREATE TABLE dbo.UsosCupones (
    IDUsoCupon      INT IDENTITY(1,1) CONSTRAINT PK_UsosCupones PRIMARY KEY,
    IDCupon         INT           NOT NULL CONSTRAINT FK_UsosCupones_Cupones  REFERENCES dbo.Cupones (IDCupon),
    IDUsuario       INT           NOT NULL CONSTRAINT FK_UsosCupones_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    IDPedido        INT           NOT NULL,
    MontoDescuento  DECIMAL(18,2) NOT NULL,
    Estado          NVARCHAR(10)  NOT NULL CONSTRAINT DF_UsosCupones_Estado DEFAULT N'APLICADO',
    Fecha           DATETIME2(0)  NOT NULL CONSTRAINT DF_UsosCupones_Fecha DEFAULT SYSUTCDATETIME(),
    FechaReversion  DATETIME2(0)  NULL,
    CONSTRAINT CK_UsosCupones_Monto  CHECK (MontoDescuento >= 0),
    CONSTRAINT CK_UsosCupones_Estado CHECK (
           (Estado = N'APLICADO'  AND FechaReversion IS NULL)
        OR (Estado = N'REVERSADO' AND FechaReversion IS NOT NULL)
    )
); 

CREATE UNIQUE INDEX UX_UsosCupones_Pedido ON dbo.UsosCupones (IDPedido);
CREATE INDEX IX_UsosCupones_Cupon_Usuario ON dbo.UsosCupones (IDCupon, IDUsuario, Estado);
CREATE INDEX IX_UsosCupones_Usuario ON dbo.UsosCupones (IDUsuario);
GO

ALTER TABLE dbo.Carritos
    ADD IDCupon INT NULL CONSTRAINT FK_Carritos_Cupones REFERENCES dbo.Cupones (IDCupon);
GO
CREATE INDEX IX_Carritos_Cupon ON dbo.Carritos (IDCupon) WHERE IDCupon IS NOT NULL;
GO

CREATE OR ALTER VIEW dbo.VW_Cupones_Conciliacion
AS
SELECT  c.IDCupon,
        c.Codigo,
        c.UsosActuales,
        ISNULL(u.Aplicados, 0)                AS UsosAplicados,
        c.UsosActuales - ISNULL(u.Aplicados, 0) AS Diferencia
FROM    dbo.Cupones c
LEFT JOIN (
        SELECT IDCupon, COUNT(*) AS Aplicados
        FROM   dbo.UsosCupones
        WHERE  Estado = N'APLICADO'
        GROUP BY IDCupon
) u ON u.IDCupon = c.IDCupon;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'015_Cupones_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'015_Cupones_Tablas.sql');
GO

CREATE TABLE dbo.MetodosEnvio (
    IDMetodoEnvio  INT IDENTITY(1,1) CONSTRAINT PK_MetodosEnvio PRIMARY KEY,
    Nombre         NVARCHAR(50)  NOT NULL CONSTRAINT UQ_MetodosEnvio_Nombre UNIQUE,
    Descripcion    NVARCHAR(255) NULL,
    Costo          DECIMAL(12,2) NOT NULL,
    DiasEstimados  INT           NOT NULL,
    Activo         BIT           NOT NULL CONSTRAINT DF_MetodosEnvio_Activo DEFAULT 1,
    FechaCreacion  DATETIME2(0)  NOT NULL CONSTRAINT DF_MetodosEnvio_FechaCreacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_MetodosEnvio_Costo CHECK (Costo >= 0),
    CONSTRAINT CK_MetodosEnvio_Dias  CHECK (DiasEstimados >= 0)
);
GO

CREATE TABLE dbo.Direcciones (
    IDDireccion        INT IDENTITY(1,1) CONSTRAINT PK_Direcciones PRIMARY KEY,
    IDUsuario          INT           NOT NULL CONSTRAINT FK_Direcciones_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    NombreDestinatario NVARCHAR(100) NOT NULL,
    Telefono           NVARCHAR(20)  NOT NULL,
    Departamento       NVARCHAR(50)  NOT NULL,
    Municipio          NVARCHAR(50)  NOT NULL,
    Direccion          NVARCHAR(250) NOT NULL,
    Referencia         NVARCHAR(250) NULL,
    EsPredeterminada   BIT           NOT NULL CONSTRAINT DF_Direcciones_EsPredeterminada DEFAULT 0,
    Activo             BIT           NOT NULL CONSTRAINT DF_Direcciones_Activo DEFAULT 1,
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Direcciones_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Direcciones_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Direcciones_Campos CHECK (
        LEN(LTRIM(RTRIM(NombreDestinatario))) > 0 AND LEN(LTRIM(RTRIM(Telefono))) > 0
        AND LEN(LTRIM(RTRIM(Departamento))) > 0 AND LEN(LTRIM(RTRIM(Municipio))) > 0
        AND LEN(LTRIM(RTRIM(Direccion))) > 0
    )
);
CREATE INDEX IX_Direcciones_Usuario ON dbo.Direcciones (IDUsuario, Activo);

CREATE UNIQUE INDEX UX_Direcciones_Predeterminada ON dbo.Direcciones (IDUsuario)
    WHERE EsPredeterminada = 1 AND Activo = 1;
GO

CREATE TABLE dbo.Pedidos (
    IDPedido           INT IDENTITY(1,1) CONSTRAINT PK_Pedidos PRIMARY KEY,
    NumeroPedido       AS (CONCAT(N'SC-', RIGHT(CONCAT(N'000000', IDPedido), 6))),
    IDUsuario          INT           NOT NULL CONSTRAINT FK_Pedidos_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    Estado             NVARCHAR(20)  NOT NULL CONSTRAINT DF_Pedidos_Estado DEFAULT N'PAGADO',
    Subtotal           DECIMAL(18,2) NOT NULL,
    Descuento          DECIMAL(18,2) NOT NULL,
    CostoEnvio         DECIMAL(18,2) NOT NULL,
    Total              DECIMAL(18,2) NOT NULL,
    BaseImponible      DECIMAL(18,2) NOT NULL,
    Iva                DECIMAL(18,2) NOT NULL,
    IDCupon            INT           NULL CONSTRAINT FK_Pedidos_Cupones REFERENCES dbo.Cupones (IDCupon),
    CodigoCupon        NVARCHAR(30)  NULL,
    IDMetodoEnvio      INT           NOT NULL CONSTRAINT FK_Pedidos_MetodosEnvio REFERENCES dbo.MetodosEnvio (IDMetodoEnvio),
    NombreEnvio        NVARCHAR(50)  NOT NULL,
    IDDireccion        INT           NULL CONSTRAINT FK_Pedidos_Direcciones REFERENCES dbo.Direcciones (IDDireccion),
    DestinatarioEnvio  NVARCHAR(100) NOT NULL,
    TelefonoEnvio      NVARCHAR(20)  NOT NULL,
    DepartamentoEnvio  NVARCHAR(50)  NOT NULL,
    MunicipioEnvio     NVARCHAR(50)  NOT NULL,
    DireccionEnvio     NVARCHAR(250) NOT NULL,
    ReferenciaEnvio    NVARCHAR(250) NULL,
    IDReserva          INT           NULL CONSTRAINT FK_Pedidos_Reservas REFERENCES dbo.Reservas (IDReserva),
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Pedidos_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Pedidos_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Pedidos_Estado CHECK (Estado IN (
        N'PAGADO', N'EN_PREPARACION', N'DESPACHADO', N'ENTREGADO', N'CANCELADO', N'DEVUELTO_PARCIAL', N'DEVUELTO')),
    CONSTRAINT CK_Pedidos_Montos CHECK (
        Subtotal >= 0 AND Descuento >= 0 AND Descuento <= Subtotal AND CostoEnvio >= 0
        AND Total = Subtotal - Descuento + CostoEnvio
        AND BaseImponible >= 0 AND Iva >= 0 AND BaseImponible + Iva = Total
    )
);
CREATE INDEX IX_Pedidos_Usuario ON dbo.Pedidos (IDUsuario, FechaCreacion DESC);
CREATE INDEX IX_Pedidos_Estado_Fecha ON dbo.Pedidos (Estado, FechaCreacion DESC) INCLUDE (Total, IDUsuario);
CREATE INDEX IX_Pedidos_Fecha ON dbo.Pedidos (FechaCreacion DESC);
CREATE UNIQUE INDEX UX_Pedidos_Reserva ON dbo.Pedidos (IDReserva) WHERE IDReserva IS NOT NULL;
GO


CREATE TABLE dbo.DetallePedidos (
    IDDetallePedido  INT IDENTITY(1,1) CONSTRAINT PK_DetallePedidos PRIMARY KEY,
    IDPedido         INT           NOT NULL CONSTRAINT FK_DetallePedidos_Pedidos  REFERENCES dbo.Pedidos (IDPedido),
    IDVariante       INT           NOT NULL CONSTRAINT FK_DetallePedidos_Variantes REFERENCES dbo.Variantes (IDVariante),
    SKU              NVARCHAR(50)  NOT NULL,
    NombreProducto   NVARCHAR(150) NOT NULL,
    Atributos        NVARCHAR(250) NULL,
    PrecioUnitario   DECIMAL(12,2) NOT NULL,
    Cantidad         INT           NOT NULL,
    Subtotal         DECIMAL(18,2) NOT NULL,
    DescuentoLinea   DECIMAL(18,2) NOT NULL CONSTRAINT DF_DetallePedidos_DescuentoLinea DEFAULT 0,
    CantidadDevuelta INT           NOT NULL CONSTRAINT DF_DetallePedidos_CantidadDevuelta DEFAULT 0,
    CONSTRAINT UQ_DetallePedidos_Linea UNIQUE (IDPedido, IDVariante),
    CONSTRAINT CK_DetallePedidos_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetallePedidos_Precio CHECK (PrecioUnitario > 0),
    CONSTRAINT CK_DetallePedidos_Subtotal CHECK (Subtotal = CAST(Cantidad AS DECIMAL(18,2)) * PrecioUnitario),
    CONSTRAINT CK_DetallePedidos_Descuento CHECK (DescuentoLinea >= 0 AND DescuentoLinea <= Subtotal),

    CONSTRAINT CK_DetallePedidos_Devuelta CHECK (CantidadDevuelta >= 0 AND CantidadDevuelta <= Cantidad)
);
CREATE INDEX IX_DetallePedidos_Variante ON dbo.DetallePedidos (IDVariante);
GO


CREATE TABLE dbo.HistorialEstadosPedido (
    IDHistorial    BIGINT IDENTITY(1,1) CONSTRAINT PK_HistorialEstadosPedido PRIMARY KEY,
    IDPedido       INT           NOT NULL CONSTRAINT FK_HistorialEstadosPedido_Pedidos REFERENCES dbo.Pedidos (IDPedido),
    EstadoAnterior NVARCHAR(20)  NULL,
    EstadoNuevo    NVARCHAR(20)  NOT NULL,
    IDUsuario      INT           NOT NULL CONSTRAINT FK_HistorialEstadosPedido_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    Fecha          DATETIME2(0)  NOT NULL CONSTRAINT DF_HistorialEstadosPedido_Fecha DEFAULT SYSUTCDATETIME(),
    Comentario     NVARCHAR(255) NULL,
    CONSTRAINT CK_HistorialEstadosPedido_Estados CHECK (
        EstadoNuevo IN (N'PAGADO', N'EN_PREPARACION', N'DESPACHADO', N'ENTREGADO', N'CANCELADO', N'DEVUELTO_PARCIAL', N'DEVUELTO')
        AND (EstadoAnterior IS NULL OR EstadoAnterior IN (N'PAGADO', N'EN_PREPARACION', N'DESPACHADO', N'ENTREGADO', N'CANCELADO', N'DEVUELTO_PARCIAL', N'DEVUELTO'))
    )
);
CREATE INDEX IX_HistorialEstadosPedido_Pedido ON dbo.HistorialEstadosPedido (IDPedido, IDHistorial);
GO

CREATE TABLE dbo.Pagos (
    IDPago             INT IDENTITY(1,1) CONSTRAINT PK_Pagos PRIMARY KEY,
    IDUsuario          INT           NOT NULL CONSTRAINT FK_Pagos_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    ClaveIdempotencia  NVARCHAR(64)  NOT NULL,
    IDCarrito          INT           NOT NULL CONSTRAINT FK_Pagos_Carritos REFERENCES dbo.Carritos (IDCarrito),
    IDReserva          INT           NULL CONSTRAINT FK_Pagos_Reservas REFERENCES dbo.Reservas (IDReserva),
    IDDireccion        INT           NOT NULL CONSTRAINT FK_Pagos_Direcciones REFERENCES dbo.Direcciones (IDDireccion),
    IDMetodoEnvio      INT           NOT NULL CONSTRAINT FK_Pagos_MetodosEnvio REFERENCES dbo.MetodosEnvio (IDMetodoEnvio),
    Monto              DECIMAL(18,2) NOT NULL,
    Estado             NVARCHAR(12)  NOT NULL CONSTRAINT DF_Pagos_Estado DEFAULT N'INICIADO',
    ReferenciaPasarela NVARCHAR(100) NULL,
    Motivo             NVARCHAR(255) NULL,
    IDPedido           INT           NULL CONSTRAINT FK_Pagos_Pedidos REFERENCES dbo.Pedidos (IDPedido),
    FechaCreacion      DATETIME2(0)  NOT NULL CONSTRAINT DF_Pagos_FechaCreacion DEFAULT SYSUTCDATETIME(),
    FechaActualizacion DATETIME2(0)  NOT NULL CONSTRAINT DF_Pagos_FechaActualizacion DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Pagos_Estado CHECK (Estado IN (N'INICIADO', N'APROBADO', N'RECHAZADO', N'EXPIRADO', N'ANULADO')),
    CONSTRAINT CK_Pagos_Monto CHECK (Monto >= 0),
    CONSTRAINT CK_Pagos_Pedido CHECK (
           (Estado = N'APROBADO' AND IDPedido IS NOT NULL)
        OR (Estado <> N'APROBADO' AND IDPedido IS NULL)
    ),
    CONSTRAINT UX_Pagos_Clave UNIQUE (IDUsuario, ClaveIdempotencia)
);
CREATE UNIQUE INDEX UX_Pagos_Pedido ON dbo.Pagos (IDPedido) WHERE IDPedido IS NOT NULL;
CREATE INDEX IX_Pagos_Carrito ON dbo.Pagos (IDCarrito);
GO

ALTER TABLE dbo.UsosCupones
    ADD CONSTRAINT FK_UsosCupones_Pedidos FOREIGN KEY (IDPedido) REFERENCES dbo.Pedidos (IDPedido);
GO

CREATE OR ALTER TRIGGER dbo.TR_Pedidos_NoEliminar ON dbo.Pedidos
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50115, N'Los pedidos no se eliminan; use la cancelación.', 1;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_Pedidos_Congelado ON dbo.Pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(IDUsuario) OR UPDATE(Subtotal) OR UPDATE(Descuento) OR UPDATE(CostoEnvio) OR UPDATE(Total)
       OR UPDATE(BaseImponible) OR UPDATE(Iva) OR UPDATE(IDCupon) OR UPDATE(CodigoCupon)
       OR UPDATE(IDMetodoEnvio) OR UPDATE(NombreEnvio) OR UPDATE(IDDireccion)
       OR UPDATE(DestinatarioEnvio) OR UPDATE(TelefonoEnvio) OR UPDATE(DepartamentoEnvio)
       OR UPDATE(MunicipioEnvio) OR UPDATE(DireccionEnvio) OR UPDATE(ReferenciaEnvio) OR UPDATE(IDReserva)
        THROW 50116, N'Los montos y los datos de envío de un pedido no pueden modificarse.', 1;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_DetallePedidos_NoEliminar ON dbo.DetallePedidos
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50115, N'Las líneas de un pedido no se eliminan.', 1;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_DetallePedidos_Congelado ON dbo.DetallePedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(IDPedido) OR UPDATE(IDVariante) OR UPDATE(SKU) OR UPDATE(NombreProducto) OR UPDATE(Atributos)
       OR UPDATE(PrecioUnitario) OR UPDATE(Cantidad) OR UPDATE(Subtotal) OR UPDATE(DescuentoLinea)
        THROW 50116, N'El precio, la cantidad y el descuento de una línea de pedido no pueden modificarse.', 1;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_HistorialEstadosPedido_Inmutable ON dbo.HistorialEstadosPedido
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50117, N'El historial de estados no puede modificarse ni eliminarse.', 1;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'018_Pedidos_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'018_Pedidos_Tablas.sql');
GO

CREATE TABLE dbo.TransicionesEstadoPedido (
    EstadoOrigen  NVARCHAR(20) NOT NULL,
    EstadoDestino NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_TransicionesEstadoPedido PRIMARY KEY (EstadoOrigen, EstadoDestino),
    CONSTRAINT CK_TransicionesEstadoPedido_Origen CHECK (EstadoOrigen IN (
        N'PAGADO', N'EN_PREPARACION', N'DESPACHADO', N'ENTREGADO', N'CANCELADO', N'DEVUELTO_PARCIAL', N'DEVUELTO')),
    CONSTRAINT CK_TransicionesEstadoPedido_Destino CHECK (EstadoDestino IN (
        N'PAGADO', N'EN_PREPARACION', N'DESPACHADO', N'ENTREGADO', N'CANCELADO', N'DEVUELTO_PARCIAL', N'DEVUELTO')),
    CONSTRAINT CK_TransicionesEstadoPedido_Distintos CHECK (EstadoOrigen <> EstadoDestino)
);
GO

CREATE TABLE dbo.Devoluciones (
    IDDevolucion   INT IDENTITY(1,1) CONSTRAINT PK_Devoluciones PRIMARY KEY,
    IDPedido       INT           NOT NULL CONSTRAINT FK_Devoluciones_Pedidos  REFERENCES dbo.Pedidos (IDPedido),
    IDUsuario      INT           NOT NULL CONSTRAINT FK_Devoluciones_Usuarios REFERENCES dbo.Usuarios (IDUsuario),
    Motivo         NVARCHAR(255) NOT NULL,
    MontoReembolso DECIMAL(18,2) NOT NULL,
    Fecha          DATETIME2(0)  NOT NULL CONSTRAINT DF_Devoluciones_Fecha DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Devoluciones_Motivo CHECK (LEN(LTRIM(RTRIM(Motivo))) > 0),
    CONSTRAINT CK_Devoluciones_Monto  CHECK (MontoReembolso >= 0)
);
CREATE INDEX IX_Devoluciones_Pedido ON dbo.Devoluciones (IDPedido);
CREATE INDEX IX_Devoluciones_Fecha  ON dbo.Devoluciones (Fecha DESC);
GO

CREATE TABLE dbo.DetalleDevoluciones (
    IDDevolucion    INT NOT NULL CONSTRAINT FK_DetalleDevoluciones_Devoluciones REFERENCES dbo.Devoluciones (IDDevolucion),
    IDDetallePedido INT NOT NULL CONSTRAINT FK_DetalleDevoluciones_DetallePedidos REFERENCES dbo.DetallePedidos (IDDetallePedido),
    Cantidad        INT NOT NULL,
    MontoReembolso  DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_DetalleDevoluciones PRIMARY KEY (IDDevolucion, IDDetallePedido),
    CONSTRAINT CK_DetalleDevoluciones_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleDevoluciones_Monto CHECK (MontoReembolso >= 0)
);
CREATE INDEX IX_DetalleDevoluciones_Detalle ON dbo.DetalleDevoluciones (IDDetallePedido);
GO

CREATE OR ALTER TRIGGER dbo.TR_Pedidos_ValidarTransicion ON dbo.Pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Estado)
       AND EXISTS (
            SELECT 1
            FROM   inserted i
            JOIN   deleted d ON d.IDPedido = i.IDPedido
            WHERE  i.Estado <> d.Estado
              AND  NOT EXISTS (SELECT 1 FROM dbo.TransicionesEstadoPedido t
                               WHERE t.EstadoOrigen = d.Estado AND t.EstadoDestino = i.Estado)
       )
        THROW 50120, N'Transición de estado de pedido no permitida.', 1;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_Devoluciones_Inmutable ON dbo.Devoluciones
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50126, N'Las devoluciones no pueden modificarse ni eliminarse.', 1;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_DetalleDevoluciones_Inmutable ON dbo.DetalleDevoluciones
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50126, N'Las devoluciones no pueden modificarse ni eliminarse.', 1;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'021_Gestion_Pedidos_Tablas.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'021_Gestion_Pedidos_Tablas.sql');
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