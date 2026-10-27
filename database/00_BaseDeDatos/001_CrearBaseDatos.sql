/* =============================================================================
   001_CrearBaseDatos.sql
   Crea la base de datos ShopCart.
   Collation CI/AS: los correos se comparan sin distinguir mayúsculas.
   ============================================================================= */

USE master;
GO

IF DB_ID(N'ShopCart') IS NULL
BEGIN
    CREATE DATABASE ShopCart COLLATE Latin1_General_100_CI_AS;
END;
GO