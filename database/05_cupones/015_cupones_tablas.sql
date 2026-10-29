/* =============================================================================
   015_Cupones_Tablas.sql
   Módulo 5 - Cupones: Cupones, UsosCupones, Carritos.IDCupon y conciliación.

   Decisiones:
     - Un cupón por pedido: el carrito tiene una sola columna IDCupon, y
       UsosCupones tiene un índice único por IDPedido.
     - El uso del cupón se CONSUME al crear el pedido (módulo 6), no al aplicarlo
       al carrito: aplicar solo valida y muestra el descuento.
     - El límite total se protege en la BD: UsosActuales <= LimiteUsosTotal.
     - Cancelar un pedido (antes del despacho) REVIERTE el uso del cupón;
       una devolución no lo revierte.
     - Todas las fechas se guardan en UTC.
     - UsosCupones.IDPedido recibe su llave foránea en el módulo de pedidos.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
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