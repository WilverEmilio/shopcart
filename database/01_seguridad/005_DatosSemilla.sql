/* =============================================================================
   005_DatosSemilla.sql
   Datos semilla del módulo de seguridad. Reejecutable: no duplica registros.
   El primer Administrador NO se crea aquí (requiere hash de contraseña);
   se crea con el script de semillas del backend.
   ============================================================================= */
USE ShopCart;
GO
SET NOCOUNT ON;
GO

INSERT INTO dbo.Roles (Nombre, Descripcion)
SELECT v.Nombre, v.Descripcion
FROM (VALUES
    (N'Cliente',       N'Compra y consulta únicamente su propia información'),
    (N'Operador',      N'Gestiona pedidos e inventario'),
    (N'Administrador', N'Gestiona además catálogo, precios, cupones, usuarios y reportes')
) AS v (Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles r WHERE r.Nombre = v.Nombre);
GO

INSERT INTO dbo.Permisos (Codigo, Descripcion)
SELECT v.Codigo, v.Descripcion
FROM (VALUES
    (N'COMPRAR',              N'Carrito, checkout, direcciones y pedidos propios'),
    (N'PEDIDOS_GESTIONAR',    N'Preparar, despachar, avanzar, cancelar y devolver pedidos'),
    (N'INVENTARIO_GESTIONAR', N'Consultar kardex y registrar movimientos y ajustes de inventario'),
    (N'CATALOGO_GESTIONAR',   N'Administrar categorías, productos y variantes'),
    (N'PRECIOS_GESTIONAR',    N'Modificar precios de las variantes'),
    (N'CUPONES_GESTIONAR',    N'Administrar cupones y promociones'),
    (N'USUARIOS_GESTIONAR',   N'Crear, consultar y desactivar usuarios'),
    (N'REPORTES_VER',         N'Consultar dashboard y reportes'),
    (N'BITACORA_VER',         N'Consultar la bitácora de auditoría')
) AS v (Codigo, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = v.Codigo);
GO

INSERT INTO dbo.RolesPermisos (IDRol, IDPermiso)
SELECT r.IDRol, p.IDPermiso
FROM (VALUES
    (N'Cliente',       N'COMPRAR'),

    (N'Operador',      N'PEDIDOS_GESTIONAR'),
    (N'Operador',      N'INVENTARIO_GESTIONAR'),

    (N'Administrador', N'PEDIDOS_GESTIONAR'),
    (N'Administrador', N'INVENTARIO_GESTIONAR'),
    (N'Administrador', N'CATALOGO_GESTIONAR'),
    (N'Administrador', N'PRECIOS_GESTIONAR'),
    (N'Administrador', N'CUPONES_GESTIONAR'),
    (N'Administrador', N'USUARIOS_GESTIONAR'),
    (N'Administrador', N'REPORTES_VER'),
    (N'Administrador', N'BITACORA_VER')
) AS m (Rol, Permiso)
JOIN dbo.Roles    r ON r.Nombre = m.Rol
JOIN dbo.Permisos p ON p.Codigo = m.Permiso
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.RolesPermisos rp
    WHERE rp.IDRol = r.IDRol AND rp.IDPermiso = p.IDPermiso
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.VersionesEsquema WHERE Script = N'003_Seguridad_Semilla.sql')
    INSERT INTO dbo.VersionesEsquema (Script) VALUES (N'003_Seguridad_Semilla.sql');
GO