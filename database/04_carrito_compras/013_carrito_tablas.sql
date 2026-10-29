/* =============================================================================
   013_Carrito_Tablas.sql
   Módulo 4 - Carrito de compras: Carritos, CarritosDetalle y FU_Carrito_Totales.

   Reglas del modelo:
     - Un carrito pertenece a un usuario O a un invitado (token), nunca a ambos.
     - Del token del invitado solo se guarda su hash SHA-256.
     - El carrito NO guarda precios: muestra el precio vigente de la variante.
       El precio se congela al crear el pedido.
     - El carrito NO reserva existencia: la reserva ocurre al iniciar el pago.
     - "Abandonado" no es un estado: se deriva (ACTIVO, con líneas y sin
       actividad durante el periodo configurable) en el módulo de reportes.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
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