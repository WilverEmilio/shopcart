/* =============================================================================
   019_Checkout_Semilla.sql
   Métodos de envío de ejemplo (costos en quetzales, IVA incluido). Reejecutable.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.MetodosEnvio (Nombre, Descripcion, Costo, DiasEstimados)
SELECT v.Nombre, v.Descripcion, v.Costo, v.DiasEstimados
FROM (VALUES
    (N'Recoger en tienda', N'Retira tu pedido en la tienda sin costo',     0.00, 1),
    (N'Envío estándar',    N'Entrega a domicilio en 3 a 5 días hábiles',    35.00, 4),
    (N'Envío express',     N'Entrega a domicilio al siguiente día hábil',   60.00, 1)
) AS v (Nombre, Descripcion, Costo, DiasEstimados)
WHERE NOT EXISTS (SELECT 1 FROM dbo.MetodosEnvio m WHERE m.Nombre = v.Nombre);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'019_Checkout_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'019_Checkout_Semilla.sql');
GO