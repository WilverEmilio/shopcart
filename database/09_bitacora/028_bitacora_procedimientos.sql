/* ---------------------------------------------------------------------------
   004_CrearPrecedimientoAlmacenados.sql
   Módulo 9 - Bitácora
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.SP_Bitacora_Registrar
    @IDUsuario     INT           = NULL,
    @Modulo        NVARCHAR(50),
    @Entidad       NVARCHAR(50),
    @IDEntidad     BIGINT        = NULL,
    @Accion        NVARCHAR(20),
    @ValorAnterior NVARCHAR(MAX) = NULL,
    @ValorNuevo    NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Bitacora (IDUsuario, Modulo, Entidad, IDEntidad, Accion, ValorAnterior, ValorNuevo)
    VALUES (@IDUsuario, @Modulo, @Entidad, @IDEntidad, @Accion, @ValorAnterior, @ValorNuevo);
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Bitacora_Listar
    @IDUsuarioActor INT,
    @Modulo         NVARCHAR(50) = NULL,
    @IDUsuario      INT          = NULL,
    @FechaDesde     DATETIME2(0) = NULL,
    @FechaHasta     DATETIME2(0) = NULL,
    @Pagina         INT          = 1,
    @TamanoPagina   INT          = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarAdministrador @IDUsuarioActor = @IDUsuarioActor;

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    SELECT  b.IDBitacora,
            b.Fecha,
            b.Modulo,
            b.Entidad,
            b.IDEntidad,
            b.Accion,
            b.ValorAnterior,
            b.ValorNuevo,
            b.IDUsuario,
            u.Correo AS CorreoUsuario,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.Bitacora b
    LEFT JOIN dbo.Usuarios u ON u.IDUsuario = b.IDUsuario
    WHERE   (@Modulo     IS NULL OR b.Modulo    = @Modulo)
        AND (@IDUsuario  IS NULL OR b.IDUsuario = @IDUsuario)
        AND (@FechaDesde IS NULL OR b.Fecha    >= @FechaDesde)
        AND (@FechaHasta IS NULL OR b.Fecha    <= @FechaHasta)
    ORDER BY b.Fecha DESC, b.IDBitacora DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO