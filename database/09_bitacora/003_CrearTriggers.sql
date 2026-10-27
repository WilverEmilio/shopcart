/* ---------------------------------------------------------------------------
   003_CrearTriggers.sql
   Módulo 9 - Bitácora

    Códigos de error personalizados (THROW):
     50030 La bitácora es inmutable                       -> 500
   --------------------------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.TR_Bitacora_Inmutable ON dbo.Bitacora
INSTEAD OF UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50030, N'La bit�cora no puede modificarse ni eliminarse.', 1;
END;
GO