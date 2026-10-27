CREATE OR ALTER TRIGGER dbo.TR_Usuarios_NoEliminar ON dbo.Usuarios
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    THROW 50031, N'Los usuarios no se eliminan; deben desactivarse.', 1;
END;
GO