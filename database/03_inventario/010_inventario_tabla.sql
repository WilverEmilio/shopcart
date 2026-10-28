/* =============================================================================
   010_inventario_tablas.sql
   Módulo 3 - Inventario: MovimientosInventario (kardex), Reservas,
   ReservasDetalle, vista de conciliación y esquema Interno.

   Modelo de existencias:
     - Variantes.ExistenciaFisica y Variantes.ExistenciaReservada son contadores.
     - MovimientosInventario es la fuente de verdad: ExistenciaFisica debe ser
       siempre igual a SUM(Cantidad) del kardex (ver VW_Inventario_Conciliacion).
     - Cantidad lleva signo: positiva entra, negativa sale.
     - Solo Interno.SP_Inventario_AplicarMovimiento modifica ExistenciaFisica.

   Esquema Interno: contiene SPs que NO deben ser invocados por la aplicación
   (no validan al usuario). El rol RolShopCartApp solo tiene EXECUTE sobre dbo;
   los SPs de dbo los alcanzan por encadenamiento de propiedad (mismo dueño).
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
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
    CONSTRAINT CK_MovimientosInventario_Referencia CHECK ((TipoReferencia IS NULL) = (IDReferencia IS NULL))
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