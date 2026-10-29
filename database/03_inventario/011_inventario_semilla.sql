/* =============================================================================
   012_Inventario_Semilla.sql
   1) Usuario de sistema (inactivo, sin acceso): firma la carga inicial y los
      procesos automáticos en el kardex.
   2) Stock inicial de todas las variantes, registrado como movimientos ENTRADA
      en el kardex, de modo que la existencia coincide con la suma de movimientos.

   Datos de prueba:
     - Una de cada 7 variantes queda SIN existencia (para probar disponibilidad).
     - TEN-DEP-42-BLA queda con 1 unidad (para probar la "última unidad").
   Reejecutable: no duplica la carga inicial.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'sistema@shopcart.local')
    INSERT INTO dbo.Usuarios (IDRol, Correo, PasswordHash, Nombres, Apellidos, Activo)
    SELECT r.IDRol, N'sistema@shopcart.local', N'!SIN-ACCESO', N'Sistema', N'ShopCart', 0
    FROM   dbo.Roles r
    WHERE  r.Nombre = N'Operador';
GO

DECLARE @IDSistema INT = (SELECT IDUsuario FROM dbo.Usuarios WHERE Correo = N'sistema@shopcart.local');

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.MovimientosInventario
        (IDVariante, TipoMovimiento, Cantidad, ExistenciaResultante, Motivo, IDUsuario)
    SELECT  v.IDVariante, N'ENTRADA', s.Cantidad, s.Cantidad, N'Carga inicial de inventario', @IDSistema
    FROM    dbo.Variantes v
    CROSS APPLY (
        SELECT CASE WHEN v.SKU = N'TEN-DEP-42-BLA' THEN 1
                    WHEN v.IDVariante % 7 = 0       THEN 0
                    ELSE 20 + (v.IDVariante * 13) % 80 END AS Cantidad
    ) s
    WHERE   s.Cantidad > 0
        AND NOT EXISTS (SELECT 1 FROM dbo.MovimientosInventario m WHERE m.IDVariante = v.IDVariante);

    UPDATE v
    SET    v.ExistenciaFisica = k.Total
    FROM   dbo.Variantes v
    JOIN  (SELECT IDVariante, SUM(Cantidad) AS Total
           FROM   dbo.MovimientosInventario
           GROUP BY IDVariante) k ON k.IDVariante = v.IDVariante;

    IF EXISTS (SELECT 1 FROM dbo.VW_Inventario_Conciliacion
               WHERE DiferenciaFisica <> 0 OR DiferenciaReservada <> 0)
        THROW 50099, N'La conciliación del inventario inicial presenta diferencias.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'012_Inventario_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'012_Inventario_Semilla.sql');
GO