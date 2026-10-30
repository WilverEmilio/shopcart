/* =============================================================================
   026_Reportes_Procedimientos.sql
   Módulo 8 - Dashboard, reportes, listado de pedidos y configuración.
   Reejecutable (CREATE OR ALTER).

   Todos los reportes exigen REPORTES_VER y aceptan fechas LOCALES (DATE):
   el SP las convierte a UTC con Configuracion.OffsetHorasLocal. Si no se
   indican, usan los últimos 30 días. Se filtra por FechaCreacion (UTC) para
   aprovechar el índice y se agrupa por fecha local.
   Ver en el script 024 la definición de "venta" (pagados, no cancelados,
   neta de devoluciones).

    Códigos de error: ver el README (sección «Catálogo de códigos de error»).
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE Interno.SP_Reportes_ResolverRango
    @FechaDesde DATE          OUTPUT,
    @FechaHasta DATE          OUTPUT,
    @DesdeUtc   DATETIME2(0)  OUTPUT,
    @HastaUtc   DATETIME2(0)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                                  WHERE Clave = N'OffsetHorasLocal'), -6);

    IF @FechaHasta IS NULL SET @FechaHasta = CAST(DATEADD(HOUR, @Offset, SYSUTCDATETIME()) AS DATE);
    IF @FechaDesde IS NULL SET @FechaDesde = DATEADD(DAY, -29, @FechaHasta);

    IF @FechaDesde > @FechaHasta OR DATEDIFF(DAY, @FechaDesde, @FechaHasta) > 730
        THROW 50130, N'El rango de fechas no es válido: la fecha inicial no puede ser posterior a la final y el máximo es de 2 años.', 1;

    SET @DesdeUtc = DATEADD(HOUR, -@Offset, CAST(@FechaDesde AS DATETIME2(0)));
    SET @HastaUtc = DATEADD(HOUR, -@Offset, CAST(DATEADD(DAY, 1, @FechaHasta) AS DATETIME2(0)));
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Reportes_ResumenDashboard
    @IDUsuarioActor INT,
    @FechaDesde     DATE = NULL,
    @FechaHasta     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0), @Dias INT, @DesdePrevUtc DATETIME2(0);

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    SET @Dias = DATEDIFF(DAY, @FechaDesde, @FechaHasta) + 1;
    SET @DesdePrevUtc = DATEADD(DAY, -@Dias, @DesdeUtc);

    SELECT  @FechaDesde AS FechaDesde,
            @FechaHasta AS FechaHasta,
            a.Pedidos,
            a.VentasBrutas,
            a.Devoluciones,
            a.VentasNetas,
            CAST(CASE WHEN a.Pedidos = 0 THEN 0 ELSE ROUND(a.VentasNetas / a.Pedidos, 2) END AS DECIMAL(18,2)) AS TicketPromedio,
            u.UnidadesNetas,
            c.PedidosCancelados,
            c.MontoCancelado,
            p.PedidosAnterior,
            p.VentasNetasAnterior,
            ab.CarritosAbandonados,
            ab.ValorCarritosAbandonados
    FROM   (SELECT  COUNT(*)                         AS Pedidos,
                    ISNULL(SUM(Total), 0)            AS VentasBrutas,
                    ISNULL(SUM(Devuelto), 0)         AS Devoluciones,
                    ISNULL(SUM(VentaNeta), 0)        AS VentasNetas
            FROM    dbo.VW_Dashboard_VentasPorPedido
            WHERE   FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc) a
    CROSS JOIN (SELECT ISNULL(SUM(UnidadesNetas), 0) AS UnidadesNetas
                FROM   dbo.VW_Dashboard_VentasPorLinea
                WHERE  FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc) u
    CROSS JOIN (SELECT COUNT(*) AS PedidosCancelados, ISNULL(SUM(Total), 0) AS MontoCancelado
                FROM   dbo.Pedidos
                WHERE  Estado = N'CANCELADO' AND FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc) c
    CROSS JOIN (SELECT COUNT(*) AS PedidosAnterior, ISNULL(SUM(VentaNeta), 0) AS VentasNetasAnterior
                FROM   dbo.VW_Dashboard_VentasPorPedido
                WHERE  FechaCreacion >= @DesdePrevUtc AND FechaCreacion < @DesdeUtc) p
    CROSS JOIN (SELECT COUNT(*) AS CarritosAbandonados, ISNULL(SUM(Valor), 0) AS ValorCarritosAbandonados
                FROM   dbo.VW_Dashboard_CarritosAbandonados) ab;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Reportes_VentasPorPeriodo
    @IDUsuarioActor INT,
    @FechaDesde     DATE         = NULL,
    @FechaHasta     DATE         = NULL,
    @Agrupacion     NVARCHAR(10) = N'DIA'
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    SET @Agrupacion = UPPER(LTRIM(RTRIM(ISNULL(@Agrupacion, N'DIA'))));
    IF @Agrupacion NOT IN (N'DIA', N'SEMANA', N'MES')
        THROW 50053, N'La agrupación debe ser DIA, SEMANA o MES.', 1;

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0);
    DECLARE @Base DATE = '19000101'; 

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    ;WITH Dias AS (
        SELECT TOP (DATEDIFF(DAY, @FechaDesde, @FechaHasta) + 1)
               DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @FechaDesde) AS Dia
        FROM   sys.all_objects a CROSS JOIN sys.all_objects b
    ),
    Periodos AS (
        SELECT DISTINCT
               CASE @Agrupacion
                    WHEN N'DIA'    THEN Dia
                    WHEN N'SEMANA' THEN DATEADD(DAY, -(DATEDIFF(DAY, @Base, Dia) % 7), Dia)
                    ELSE DATEFROMPARTS(YEAR(Dia), MONTH(Dia), 1)
               END AS Inicio
        FROM   Dias
    ),
    Ventas AS (
        SELECT  x.Inicio,
                COUNT(*)          AS Pedidos,
                SUM(x.Total)      AS VentasBrutas,
                SUM(x.Devuelto)   AS Devoluciones,
                SUM(x.VentaNeta)  AS VentasNetas
        FROM (
            SELECT  CASE @Agrupacion
                         WHEN N'DIA'    THEN FechaLocal
                         WHEN N'SEMANA' THEN DATEADD(DAY, -(DATEDIFF(DAY, @Base, FechaLocal) % 7), FechaLocal)
                         ELSE DATEFROMPARTS(YEAR(FechaLocal), MONTH(FechaLocal), 1)
                    END AS Inicio,
                    Total, Devuelto, VentaNeta
            FROM    dbo.VW_Dashboard_VentasPorPedido
            WHERE   FechaCreacion >= @DesdeUtc AND FechaCreacion < @HastaUtc
        ) x
        GROUP BY x.Inicio
    )
    SELECT  p.Inicio AS PeriodoInicio,
            CASE @Agrupacion
                 WHEN N'DIA'    THEN CONVERT(NVARCHAR(10), p.Inicio, 23)
                 WHEN N'SEMANA' THEN CONCAT(N'Sem ', CONVERT(NVARCHAR(10), p.Inicio, 23))
                 ELSE LEFT(CONVERT(NVARCHAR(10), p.Inicio, 23), 7)
            END AS Etiqueta,
            ISNULL(v.Pedidos, 0)       AS Pedidos,
            ISNULL(v.VentasBrutas, 0)  AS VentasBrutas,
            ISNULL(v.Devoluciones, 0)  AS Devoluciones,
            ISNULL(v.VentasNetas, 0)   AS VentasNetas,
            CAST(CASE WHEN ISNULL(v.Pedidos, 0) = 0 THEN 0
                      ELSE ROUND(v.VentasNetas / v.Pedidos, 2) END AS DECIMAL(18,2)) AS TicketPromedio
    FROM    Periodos p
    LEFT JOIN Ventas v ON v.Inicio = p.Inicio
    ORDER BY p.Inicio;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Reportes_VentasPorCategoria
    @IDUsuarioActor INT,
    @FechaDesde     DATE = NULL,
    @FechaHasta     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0);

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    SELECT  l.IDCategoria,
            l.Categoria,
            SUM(l.UnidadesNetas)           AS Unidades,
            SUM(l.VentaNeta)               AS VentasNetas,
            COUNT(DISTINCT l.IDPedido)     AS Pedidos,
            CAST(ROUND(100.0 * SUM(l.VentaNeta) / NULLIF(SUM(SUM(l.VentaNeta)) OVER (), 0), 2) AS DECIMAL(5,2)) AS Porcentaje
    FROM    dbo.VW_Dashboard_VentasPorLinea l
    WHERE   l.FechaCreacion >= @DesdeUtc AND l.FechaCreacion < @HastaUtc
    GROUP BY l.IDCategoria, l.Categoria
    HAVING  SUM(l.UnidadesNetas) > 0
    ORDER BY SUM(l.VentaNeta) DESC, l.IDCategoria;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Reportes_TopProductos
    @IDUsuarioActor INT,
    @FechaDesde     DATE         = NULL,
    @FechaHasta     DATE         = NULL,
    @Top            INT          = 10,
    @OrdenarPor     NVARCHAR(10) = N'UNIDADES' 
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    SET @OrdenarPor = UPPER(LTRIM(RTRIM(ISNULL(@OrdenarPor, N'UNIDADES'))));
    IF @OrdenarPor NOT IN (N'UNIDADES', N'VENTAS')
        THROW 50053, N'El orden debe ser UNIDADES o VENTAS.', 1;
    IF @Top IS NULL OR @Top < 1 SET @Top = 10;
    IF @Top > 50 SET @Top = 50;

    DECLARE @DesdeUtc DATETIME2(0), @HastaUtc DATETIME2(0);

    EXEC Interno.SP_Reportes_ResolverRango
        @FechaDesde = @FechaDesde OUTPUT, @FechaHasta = @FechaHasta OUTPUT,
        @DesdeUtc = @DesdeUtc OUTPUT, @HastaUtc = @HastaUtc OUTPUT;

    ;WITH Agg AS (
        SELECT  l.IDProducto, l.Producto, l.Categoria,
                SUM(l.UnidadesNetas) AS Unidades,
                SUM(l.VentaNeta)     AS VentasNetas
        FROM    dbo.VW_Dashboard_VentasPorLinea l
        WHERE   l.FechaCreacion >= @DesdeUtc AND l.FechaCreacion < @HastaUtc
        GROUP BY l.IDProducto, l.Producto, l.Categoria
        HAVING  SUM(l.UnidadesNetas) > 0
    )
    SELECT TOP (@Top)
            ROW_NUMBER() OVER (ORDER BY CASE WHEN @OrdenarPor = N'VENTAS' THEN VentasNetas END DESC,
                                        Unidades DESC, IDProducto) AS Ranking,
            IDProducto, Producto, Categoria, Unidades, VentasNetas
    FROM    Agg
    ORDER BY Ranking;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Reportes_CarritosAbandonados
    @IDUsuarioActor INT,
    @OrdenarPor     NVARCHAR(20) = N'HorasInactivo', 
    @Direccion      NVARCHAR(4)  = N'DESC',
    @Pagina         INT          = 1,
    @TamanoPagina   INT          = 20
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'REPORTES_VER';

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    SELECT  c.IDCarrito, c.Cliente, c.EsInvitado, c.Lineas, c.Unidades, c.Valor,
            c.FechaCreacion, c.FechaActualizacion, c.HorasInactivo,
            COUNT(*)      OVER () AS TotalRegistros,
            SUM(c.Valor)  OVER () AS ValorTotal
    FROM    dbo.VW_Dashboard_CarritosAbandonados c
    ORDER BY
        CASE WHEN @OrdenarPor = N'HorasInactivo' AND @Direccion = N'ASC'  THEN c.HorasInactivo END ASC,
        CASE WHEN @OrdenarPor = N'HorasInactivo' AND @Direccion = N'DESC' THEN c.HorasInactivo END DESC,
        CASE WHEN @OrdenarPor = N'Valor'         AND @Direccion = N'ASC'  THEN c.Valor         END ASC,
        CASE WHEN @OrdenarPor = N'Valor'         AND @Direccion = N'DESC' THEN c.Valor         END DESC,
        CASE WHEN @OrdenarPor = N'Unidades'      AND @Direccion = N'ASC'  THEN c.Unidades      END ASC,
        CASE WHEN @OrdenarPor = N'Unidades'      AND @Direccion = N'DESC' THEN c.Unidades      END DESC,
        c.IDCarrito
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO


CREATE OR ALTER PROCEDURE dbo.SP_Pedidos_Listar
    @IDUsuarioActor INT,
    @Estado         NVARCHAR(20)  = NULL,
    @IDCliente      INT           = NULL,
    @Texto          NVARCHAR(100) = NULL,
    @FechaDesde     DATE          = NULL,
    @FechaHasta     DATE          = NULL,
    @OrdenarPor     NVARCHAR(20)  = N'Fecha',
    @Direccion      NVARCHAR(4)   = N'DESC',
    @Pagina         INT           = 1,
    @TamanoPagina   INT           = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.Usuarios u
        JOIN dbo.RolesPermisos rp ON rp.IDRol = u.IDRol
        JOIN dbo.Permisos p       ON p.IDPermiso = rp.IDPermiso
        WHERE u.IDUsuario = @IDUsuarioActor AND u.Activo = 1
          AND p.Codigo IN (N'PEDIDOS_GESTIONAR', N'REPORTES_VER'))
        THROW 50016, N'No tiene permisos para realizar esta acción.', 1;

    IF @FechaDesde IS NOT NULL AND @FechaHasta IS NOT NULL AND @FechaDesde > @FechaHasta
        THROW 50130, N'El rango de fechas no es válido: la fecha inicial no puede ser posterior a la final.', 1;

    IF @Pagina < 1 SET @Pagina = 1;
    IF @TamanoPagina < 1 SET @TamanoPagina = 20;
    IF @TamanoPagina > 100 SET @TamanoPagina = 100;

    DECLARE @Offset INT = ISNULL((SELECT TRY_CAST(Valor AS INT) FROM dbo.Configuracion
                                  WHERE Clave = N'OffsetHorasLocal'), -6);
    DECLARE @DesdeUtc DATETIME2(0) = NULL, @HastaUtc DATETIME2(0) = NULL;

    IF @FechaDesde IS NOT NULL
        SET @DesdeUtc = DATEADD(HOUR, -@Offset, CAST(@FechaDesde AS DATETIME2(0)));
    IF @FechaHasta IS NOT NULL
        SET @HastaUtc = DATEADD(HOUR, -@Offset, CAST(DATEADD(DAY, 1, @FechaHasta) AS DATETIME2(0)));

    DECLARE @Patron NVARCHAR(102) =
        CASE WHEN @Texto IS NULL OR LTRIM(RTRIM(@Texto)) = N'' THEN NULL
             ELSE N'%' + LTRIM(RTRIM(@Texto)) + N'%' END;

    SELECT  h.IDPedido, h.NumeroPedido, h.Estado, h.IDUsuario, h.CorreoCliente, h.NombreCliente,
            h.Total, h.Devuelto, h.NombreEnvio, h.CodigoCupon, h.FechaCreacion, h.FechaActualizacion,
            COUNT(*) OVER () AS TotalRegistros
    FROM    dbo.VW_Pedidos_Historial h
    WHERE   (@Estado IS NULL OR h.Estado = @Estado)
        AND (@IDCliente IS NULL OR h.IDUsuario = @IDCliente)
        AND (@DesdeUtc IS NULL OR h.FechaCreacion >= @DesdeUtc)
        AND (@HastaUtc IS NULL OR h.FechaCreacion <  @HastaUtc)
        AND (@Patron IS NULL
             OR h.NumeroPedido  LIKE @Patron
             OR h.CorreoCliente LIKE @Patron
             OR h.NombreCliente LIKE @Patron)
    ORDER BY
        CASE WHEN @OrdenarPor = N'Fecha'   AND @Direccion = N'ASC'  THEN h.FechaCreacion END ASC,
        CASE WHEN @OrdenarPor = N'Fecha'   AND @Direccion = N'DESC' THEN h.FechaCreacion END DESC,
        CASE WHEN @OrdenarPor = N'Total'   AND @Direccion = N'ASC'  THEN h.Total         END ASC,
        CASE WHEN @OrdenarPor = N'Total'   AND @Direccion = N'DESC' THEN h.Total         END DESC,
        CASE WHEN @OrdenarPor = N'Estado'  AND @Direccion = N'ASC'  THEN h.Estado        END ASC,
        CASE WHEN @OrdenarPor = N'Estado'  AND @Direccion = N'DESC' THEN h.Estado        END DESC,
        CASE WHEN @OrdenarPor = N'Cliente' AND @Direccion = N'ASC'  THEN h.NombreCliente END ASC,
        CASE WHEN @OrdenarPor = N'Cliente' AND @Direccion = N'DESC' THEN h.NombreCliente END DESC,
        h.IDPedido DESC
    OFFSET (@Pagina - 1) * @TamanoPagina ROWS
    FETCH NEXT @TamanoPagina ROWS ONLY;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Configuracion_Listar
    @IDUsuarioActor INT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CONFIGURACION_GESTIONAR';

    SELECT Clave, Valor, Descripcion, FechaActualizacion
    FROM   dbo.Configuracion
    ORDER BY Clave;
END;
GO

CREATE OR ALTER PROCEDURE dbo.SP_Configuracion_Actualizar
    @IDUsuarioActor INT,
    @Clave          NVARCHAR(50),
    @Valor          NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.SP_Usuarios_ValidarPermiso @IDUsuarioActor = @IDUsuarioActor, @CodigoPermiso = N'CONFIGURACION_GESTIONAR';

    SET @Clave = LTRIM(RTRIM(@Clave));
    SET @Valor = LTRIM(RTRIM(@Valor));

    IF NOT EXISTS (SELECT 1 FROM dbo.Configuracion WHERE Clave = @Clave)
        THROW 50131, N'La clave de configuración no existe.', 1;

    DECLARE @Entero INT = TRY_CAST(@Valor AS INT);

    IF @Clave = N'OffsetHorasLocal' AND (@Entero IS NULL OR @Entero NOT BETWEEN -12 AND 14)
        THROW 50132, N'OffsetHorasLocal debe ser un número entero entre -12 y 14.', 1;
    IF @Clave = N'AbandonoCarritoHoras' AND (@Entero IS NULL OR @Entero NOT BETWEEN 1 AND 720)
        THROW 50132, N'AbandonoCarritoHoras debe ser un número entero entre 1 y 720.', 1;

    SET @Valor = CAST(@Entero AS NVARCHAR(20));

    DECLARE @ValorActual NVARCHAR(100), @ValorAnterior NVARCHAR(MAX), @ValorNuevo NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ValorActual = Valor
        FROM   dbo.Configuracion WITH (UPDLOCK, HOLDLOCK)
        WHERE  Clave = @Clave;

        IF @ValorActual = @Valor
        BEGIN
            COMMIT TRANSACTION;
            SELECT @Clave AS Clave, @Valor AS Valor;
            RETURN;
        END;

        UPDATE dbo.Configuracion
        SET    Valor = @Valor, FechaActualizacion = SYSUTCDATETIME()
        WHERE  Clave = @Clave;

        SET @ValorAnterior = (SELECT @Clave AS Clave, @ValorActual AS Valor FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        SET @ValorNuevo    = (SELECT @Clave AS Clave, @Valor       AS Valor FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

        EXEC dbo.SP_Bitacora_Registrar
            @IDUsuario = @IDUsuarioActor, @Modulo = N'Configuracion', @Entidad = N'Configuracion',
            @IDEntidad = NULL, @Accion = N'MODIFICAR',
            @ValorAnterior = @ValorAnterior, @ValorNuevo = @ValorNuevo;

        COMMIT TRANSACTION;

        SELECT @Clave AS Clave, @Valor AS Valor;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'026_Reportes_Procedimientos.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'026_Reportes_Procedimientos.sql');
GO