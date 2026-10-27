/* =============================================================================
   005_PermisosAplicacion.sql
   La aplicación solo puede EJECUTAR stored procedures. No tiene acceso directo
   a tablas: ni SELECT, INSERT, UPDATE ni DELETE (esto también protege la
   inmutabilidad de la bitácora aunque alguien intente TRUNCATE o DELETE).
   Los SPs siguen accediendo a las tablas por encadenamiento de propiedad (dbo).
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

IF DATABASE_PRINCIPAL_ID(N'RolShopCartApp') IS NULL
    CREATE ROLE RolShopCartApp;
GO

GRANT EXECUTE ON SCHEMA::dbo TO RolShopCartApp;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO RolShopCartApp;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'005_Seguridad_PermisosAplicacion.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'005_Seguridad_PermisosAplicacion.sql');
GO