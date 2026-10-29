/* =============================================================================
   018_Pedidos_Tablas.sql
   Módulo 6 - Checkout y pago: MetodosEnvio, Direcciones, Pedidos, DetallePedidos,
   HistorialEstadosPedido y Pagos.

   Decisiones:
     - El pedido guarda una COPIA CONGELADA de precios, descuento, envío, IVA y
       dirección. Triggers impiden modificarla: cambiar el precio de un producto
       o editar la dirección del cliente no altera pedidos ya hechos.
     - El descuento del cupón se prorratea por línea (DescuentoLinea) para poder
       calcular reembolsos exactos en devoluciones parciales.
     - Los pedidos nacen en estado PAGADO: solo se crean cuando el pago se aprueba.
       Las transiciones permitidas se definen en el módulo 7.
     - Pagos guarda la clave de idempotencia (única por usuario): repetir la misma
       solicitud nunca genera dos pedidos ni dos cobros.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
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