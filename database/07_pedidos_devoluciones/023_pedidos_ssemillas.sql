/* =============================================================================
   023_Gestion_Pedidos_Semilla.sql
   Transiciones de estado permitidas (ver el diagrama en el script 021).
   Son datos de referencia del sistema, no de prueba. Reejecutable.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.TransicionesEstadoPedido (EstadoOrigen, EstadoDestino)
SELECT v.Origen, v.Destino
FROM (VALUES
    (N'PAGADO',           N'EN_PREPARACION'),
    (N'PAGADO',           N'CANCELADO'),
    (N'EN_PREPARACION',   N'DESPACHADO'),
    (N'EN_PREPARACION',   N'CANCELADO'),
    (N'DESPACHADO',       N'ENTREGADO'),
    (N'ENTREGADO',        N'DEVUELTO_PARCIAL'),
    (N'ENTREGADO',        N'DEVUELTO'),
    (N'DEVUELTO_PARCIAL', N'DEVUELTO')
) AS v (Origen, Destino)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.TransicionesEstadoPedido t
    WHERE t.EstadoOrigen = v.Origen AND t.EstadoDestino = v.Destino
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'022_Gestion_Pedidos_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'022_Gestion_Pedidos_Semilla.sql');
GO