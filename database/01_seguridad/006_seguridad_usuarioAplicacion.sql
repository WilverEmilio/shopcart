/* =============================================================================
   006_UsuarioAplicacion.sql
   Crea el login y el usuario con el que se conecta el backend.
   La contraseña NO se guarda en el repositorio: se pasa por variable sqlcmd.

   Ejecución (la contraseña no debe contener comillas simples):
     sqlcmd -S localhost -U sa -P "<password_sa>" -b -f 65001 ^
            -v AppPassword="<password_app>" -i 006_Seguridad_UsuarioAplicacion.sql

   Luego configure en el .env del backend: DB_USER=shopcart_app y DB_PASSWORD.
   ============================================================================= */
USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'shopcart_app')
    CREATE LOGIN shopcart_app WITH PASSWORD = N'$(AppPassword)', CHECK_POLICY = ON;
GO

USE ShopCart;
GO

IF DATABASE_PRINCIPAL_ID(N'shopcart_app') IS NULL
    CREATE USER shopcart_app FOR LOGIN shopcart_app;
GO

ALTER ROLE RolShopCartApp ADD MEMBER shopcart_app;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'006_Seguridad_UsuarioAplicacion.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'006_Seguridad_UsuarioAplicacion.sql');
GO