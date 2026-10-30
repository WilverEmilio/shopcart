/* =============================================================================
   021_Gestion_Pedidos_Tablas.sql
   Módulo 7 - Gestión de pedidos y devoluciones: TransicionesEstadoPedido,
   Devoluciones, DetalleDevoluciones y el trigger que valida las transiciones.

   CICLO DE VIDA DEL PEDIDO (documentar en el README con el diagrama de estados):

       PAGADO ──> EN_PREPARACION ──> DESPACHADO ──> ENTREGADO ──> DEVUELTO_PARCIAL ──> DEVUELTO
          │              │                              └──────────────────────────────> DEVUELTO
          └──> CANCELADO <┘

     - CANCELADO es posible solo antes del despacho (PAGADO o EN_PREPARACION).
     - Las devoluciones solo proceden sobre pedidos ENTREGADOS (o ya devueltos
       parcialmente) y pueden ser totales o parciales por línea.
     - CANCELADO y DEVUELTO son estados finales.
     - Las transiciones válidas viven en TransicionesEstadoPedido y se validan
       tanto en los SPs (mensaje claro) como en un trigger (protección final).
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
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