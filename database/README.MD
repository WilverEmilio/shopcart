# Base de datos ShopCart

Scripts T-SQL (SQL Server 2019 o superior) que crean la base de datos, sus objetos y los datos semilla de forma reproducible. **No se usa ningún ORM**: todos los objetos están escritos a mano y todo el acceso a datos se hace con *stored procedures*.

Resumen: **30 tablas, 87 stored procedures** (77 en `dbo` y 10 internos en `Interno`), **4 funciones tipo tabla, 6 vistas y 11 triggers**, distribuidos en 27 scripts numerados.

> Documentación general, reglas de negocio y catálogo de códigos de error: ver el [README principal](../README.md). Modelo entidad-relación: [docs/er-diagram.md](../docs/er-diagram.md).

## Requisitos

- Microsoft SQL Server 2019 o superior (instalado o en contenedor).
- La utilidad de línea de comandos `sqlcmd` (o SSMS / Azure Data Studio ejecutando los archivos en orden).
- Un inicio de sesión con permisos para crear bases de datos y logins (por ejemplo `sa` en un entorno local).

## Ejecución

Los scripts se ejecutan **en orden numérico y sobre una base nueva**. La contraseña del usuario de la aplicación nunca se guarda en el repositorio: se pasa como variable de `sqlcmd` (`-v AppPassword`), solo la usa el script `006`.

Bash (Linux / macOS / Git Bash):

```bash
export SA_PASSWORD='<contraseña de sa>'
export APP_PASSWORD='<contraseña para shopcart_app, sin comillas simples>'

for f in database/scripts/*.sql; do
  echo ">> $f"
  sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -b -f 65001 -v AppPassword="$APP_PASSWORD" -i "$f" || break
done
```

PowerShell (Windows):

```powershell
$env:SA_PASSWORD  = '<contraseña de sa>'
$env:APP_PASSWORD = '<contraseña para shopcart_app, sin comillas simples>'

foreach ($f in Get-ChildItem database/scripts/*.sql | Sort-Object Name) {
  Write-Host ">> $($f.Name)"
  sqlcmd -S localhost -U sa -P $env:SA_PASSWORD -b -f 65001 -v AppPassword=$env:APP_PASSWORD -i $f.FullName
  if ($LASTEXITCODE -ne 0) { break }
}
```

- `-b` detiene el script ante un error y devuelve un código de salida distinto de cero.
- `-f 65001` lee los archivos como UTF-8 (los scripts contienen tildes y la ñ).
- La contraseña de `APP_PASSWORD` debe cumplir la política de contraseñas de SQL Server.

### Reiniciar desde cero

Los scripts de tablas (`CREATE TABLE`) no son reejecutables; para repetir la instalación se elimina la base y se vuelve a ejecutar todo:

```sql
USE master;
ALTER DATABASE ShopCart SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE ShopCart;
```

Los scripts de procedimientos, funciones, vistas, triggers y semillas **sí son reejecutables** (`CREATE OR ALTER` y semillas con `NOT EXISTS`).

### Conexión de la aplicación

El backend se conecta con el usuario `shopcart_app`, que pertenece al rol `RolShopCartApp`: solo puede **ejecutar** stored procedures del esquema `dbo`, y tiene denegado `SELECT/INSERT/UPDATE/DELETE` sobre las tablas. No debe usarse `sa` en la aplicación.

## Orden y contenido de los scripts

| Script | Módulo | Contenido | ¿Reejecutable? |
|---|---|---|---|
| `001_crearBaseDatos` | Base | Crea la base `ShopCart` (collation `Latin1_General_100_CI_AS`) | Sí |
| `002_seguridad_Tablas` | 1 Seguridad | `VersionesEsquema`, `Roles`, `Permisos`, `RolesPermisos`, `Usuarios`, `TokensRefresco`, `Bitacora` y sus triggers | No |
| `003_seguridad_Procedimientos` | 1 Seguridad | Registro, usuarios, tokens de refresco y bitácora | Sí |
| `004_seguridad_Semilla` | 1 Seguridad | Roles (Cliente, Operador, Administrador), permisos y matriz rol-permiso | Sí |
| `005_seguridad_PermisosAplicacion` | 1 Seguridad | Rol `RolShopCartApp`: solo `EXECUTE` sobre `dbo` | Sí |
| `006_seguridad_UsuarioAplicacion` | 1 Seguridad | Login y usuario `shopcart_app` (contraseña por variable `AppPassword`) | Sí |
| `007_Catalogo_Procedimientos` | 2 Catálogo | CRUD de categorías, productos y variantes; búsqueda | Sí |
| `008_Catalogo_Semilla` | 2 Catálogo | 8 categorías, 6 productos curados y 400 de prueba (1,200 variantes) | Sí |
| `009_Catalogo_Tablas` | 2 Catálogo | Categorías, productos, imágenes, atributos, variantes | No |
| `010_Inventario_Tablas` | 3 Inventario | Kardex, reservas, esquema `Interno`, vista de conciliación | No |
| `011_Inventario_Procedimientos` | 3 Inventario | Movimientos, reservas, kardex y conciliación | Sí |
| `012_Inventario_Semilla` | 3 Inventario | Usuario de sistema y stock inicial (como movimientos del kardex) | Sí |
| `013_Carrito_Tablas` | 4 Carrito | Carritos, detalle y `FU_Carrito_Totales` | No |
| `014_Carrito_Procedimientos` | 4 Carrito | Obtener, agregar, actualizar, eliminar y fusionar | Sí |
| `015_Cupones_Tablas` | 5 Cupones | Cupones, usos y `Carritos.IDCupon` | No |
| `016_Cupones_Procedimientos` | 5 Cupones | Cálculo de descuento, CRUD y aplicación al carrito | Sí |
| `017_Cupones_Semilla` | 5 Cupones | 6 cupones, uno por cada caso de prueba | Sí |
| `018_checkout_tablas` | 6 Checkout | Envíos, direcciones, pedidos, líneas, historial, pagos | No |
| `019_Checkout_Procedimientos` | 6 Checkout | Direcciones, iniciar pago, crear pedido, rechazar pago | Sí |
| `020_Checkout_Semilla` | 6 Checkout | 3 métodos de envío | Sí |
| `021_Pedidos_Tablas` | 7 Pedidos | Transiciones, devoluciones y trigger de validación | No |
| `022_Pedidos_Procedimientos` | 7 Pedidos | Avanzar estado, cancelar, devolver, consultar | Sí |
| `023_Pedidos_Semilla` | 7 Pedidos | Las 8 transiciones permitidas | Sí |
| `024_dashboard_tablas` | 8 Reportes | `Configuracion` y 4 vistas del dashboard | No |
| `025_dashboard_Procedimientos` | 8 Reportes | Dashboard, reportes, listado de pedidos y configuración | Sí |
| `026_dashboard_Semilla` | 8 Reportes | Configuración, 60 clientes demo, 3,000 pedidos y 18 carritos | Sí (no recarga si ya hay pedidos) |
| `027_bitacora_tablas` | 1 Seguridad | Bitacora | Sí |
| `028_bitacora_Procedimientos` | 1 seguridad | Bitacora | Sí |


Cada script, al terminar, se registra en la tabla `VersionesEsquema` (control de qué migraciones se aplicaron).

Los scripts `016`, `020` y `023` redefinen con `CREATE OR ALTER` objetos creados antes (`FU_Carrito_Totales`, `SP_Carrito_Obtener`, `SP_Inventario_ReservarExistencia`, `SP_Pedidos_ObtenerDetalle`) para añadirles funcionalidad: es el patrón de migración incremental del proyecto, y por eso no se editan los scripts ya aplicados.

## Convenciones

| Objeto | Formato | Ejemplo |
|---|---|---|
| Stored procedure | `SP_Modulo_Proceso` | `SP_Pedidos_CrearPedido` |
| Vista | `VW_Modulo_Proceso` | `VW_Dashboard_VentasPorLinea` |
| Función tipo tabla | `FU_Modulo_Proceso` | `FU_Cupones_CalculoDescuento` |
| Trigger | `TR_Tabla_Proposito` | `TR_Pedidos_ValidarTransicion` |
| Llave primaria autoincrementable | `ID` + nombre | `IDPedido`, `IDVariante` |
| Restricciones | `PK_`, `FK_`, `UQ_`/`UX_`, `CK_`, `DF_`, `IX_` | `CK_Variantes_Existencias` |

- Todos los objetos se escriben con la primera letra de cada palabra en mayúscula.
- Los parámetros de los SPs son tipados. No hay SQL dinámico concatenado; los listados con orden variable usan `CASE` en el `ORDER BY` y los datos estructurados se reciben como JSON leído con `OPENJSON`.
- Los SPs de escritura llevan `SET XACT_ABORT ON`, `BEGIN TRY/CATCH` y `THROW`.
- Los SPs que reciben `@IDUsuarioActor` validan **dentro de la base de datos** el permiso del usuario (defensa en profundidad además del middleware del backend).

## Esquema `Interno`

Contiene 10 procedimientos que **no validan al usuario** y solo deben ser invocados por otros procedimientos (`AplicarMovimiento`, `CerrarReserva`, `ConsumirReserva`, `ResolverCarrito`, `RegistrarUso`, `CambiarEstado`...). El rol de la aplicación no tiene `EXECUTE` sobre ese esquema; los SPs de `dbo` lo alcanzan por encadenamiento de propiedad. Así, aunque el backend tuviera una falla, no podría registrar un movimiento de inventario ni cambiar el estado de un pedido sin pasar por las validaciones.

## Catálogo de procedimientos

**Permiso** es el permiso que el SP exige (se valida en la base de datos). *Público* significa que no requiere sesión; *Cliente* corresponde al permiso `COMPRAR`.

### 1. Seguridad y bitácora (`004`)

| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Usuarios_RegistrarCliente` | Registro público; el rol siempre es Cliente | Público |
| `SP_Usuarios_CrearUsuarioInterno` | Crea Operadores o Administradores | `USUARIOS_GESTIONAR` (rol Administrador) |
| `SP_Usuarios_ObtenerPorCorreo` | Datos para el inicio de sesión (incluye el hash) | Backend |
| `SP_Usuarios_ObtenerPorID`, `SP_Usuarios_ObtenerPermisos` | Perfil y permisos de la sesión | Backend |
| `SP_Usuarios_Listar` | Listado paginado con filtros | Administrador |
| `SP_Usuarios_CambiarEstado` | Desactiva o reactiva (cierra sus sesiones) | Administrador |
| `SP_Tokens_Guardar`, `SP_Tokens_Rotar`, `SP_Tokens_Revocar` | Refresh tokens: login, rotación con detección de reutilización y logout | Backend |

### 2. Catálogo (`009`, `027`)

| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Categorias_Crear` / `Actualizar` / `CambiarEstado` / `Eliminar` | CRUD de categorías | `CATALOGO_GESTIONAR` |
| `SP_Categorias_ObtenerPorID` / `Listar` | Consulta pública (la tienda filtra por activas) | Público |
| `SP_Productos_Crear` | Producto con variantes, atributos e imágenes en una transacción (JSON) | `CATALOGO_GESTIONAR` |
| `SP_Productos_Actualizar` / `CambiarEstado` / `ReemplazarImagenes` | Edición | `CATALOGO_GESTIONAR` |
| `SP_Productos_Eliminar` | Elimina si no tiene historial; si tiene ventas, kardex o reservas, lo **desactiva** | `CATALOGO_GESTIONAR` |
| `SP_Productos_ObtenerDetalle` | 4 conjuntos: producto, imágenes, variantes, atributos | Público (con permiso ve inactivos y existencias reales) |
| `SP_Variantes_Crear` / `Actualizar` / `CambiarEstado` / `Eliminar` | Variantes (SKU y atributos) | `CATALOGO_GESTIONAR` |
| `SP_Variantes_CambiarPrecio` | Cambio de precio, con bitácora | `PRECIOS_GESTIONAR` |
| `SP_Catalogo_Buscar` | Texto, categoría, rango de precio, disponibilidad, orden y paginación | Público |
| `SP_Atributos_Listar` | Atributos disponibles (Talla, Color, Presentación) | Público |

### 3. Inventario (`011`)

| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Inventario_RegistrarEntrada` | Entrada (por compra, reposición) con motivo | `INVENTARIO_GESTIONAR` |
| `SP_Inventario_RegistrarAjuste` | Ajuste con signo; exige motivo y no deja existencia negativa | `INVENTARIO_GESTIONAR` |
| `SP_Inventario_ReservarExistencia` | Reserva atómica por 15 minutos | Cliente |
| `SP_Inventario_LiberarReserva` | Libera la reserva propia | Cliente (o `INVENTARIO_GESTIONAR`) |
| `SP_Inventario_LiberarReservasVencidas` | **Job**: libera las reservas vencidas | Backend |
| `SP_Inventario_ListarKardex`, `ListarExistencias`, `ObtenerConciliacion` | Consultas | `INVENTARIO_GESTIONAR` |

### 4. Carrito (`014`, `016`)

| Procedimiento | Propósito | Identifica al dueño por |
|---|---|---|
| `SP_Carrito_Obtener` | Líneas, totales y banderas (`Vendible`, `ExcedeExistencia`) | `@IDUsuario` o `@TokenHash` |
| `SP_Carrito_AgregarProducto` / `ActualizarCantidad` / `EliminarProducto` | Gestión de líneas (tope por existencia disponible) | `@IDUsuario` o `@TokenHash` |
| `SP_Carrito_Fusionar` | Une el carrito de invitado al del usuario al iniciar sesión | `@IDUsuario` + `@TokenHash` |
| `SP_Carrito_AplicarCupon` / `QuitarCupon` | Cupón del carrito (solo uno) | `@IDUsuario` |

El cliente **nunca envía un identificador de carrito**: el dueño sale del JWT o del token del invitado.

### 5. Cupones (`016`)

| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Cupones_Crear` / `Actualizar` / `CambiarEstado` / `Eliminar` | CRUD | `CUPONES_GESTIONAR` |
| `SP_Cupones_ObtenerPorID` / `Listar` | Consulta con estado derivado (VIGENTE, VENCIDO, AGOTADO...) | `CUPONES_GESTIONAR` |
| `FU_Cupones_CalculoDescuento` | Valida el cupón y calcula el descuento (única fuente de verdad) | — |
| `FU_Cupones_MensajeRechazo` | Motivo de rechazo → mensaje específico | — |

### 6. Checkout y pedidos (`020`, `023`)

| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Direcciones_Crear` / `Actualizar` / `Eliminar` / `Listar` | Direcciones del cliente (se desactivan, no se borran) | Cliente |
| `SP_Envios_Listar` | Métodos de envío | Público |
| `SP_Checkout_IniciarPago` | Valida, **reserva** y registra el pago `INICIADO` con la clave de idempotencia | Cliente |
| `SP_Pedidos_CrearPedido` | **Crea el pedido de forma atómica** al aprobarse el pago | Cliente |
| `SP_Checkout_RechazarPago` | Libera la reserva si el pago se rechaza | Cliente |
| `SP_Checkout_ExpirarPagos` | **Job**: marca `EXPIRADO` los pagos cuya reserva venció | Backend |
| `SP_Pedidos_ListarMios` | Pedidos del cliente (paginado) | Cliente |
| `SP_Pedidos_ObtenerDetalle` | Pedido, líneas, historial y devoluciones (el cliente solo ve los suyos) | Cliente o `PEDIDOS_GESTIONAR` |
| `SP_Pedidos_AvanzarEstado` | Preparar, despachar, entregar | `PEDIDOS_GESTIONAR` |
| `SP_Pedidos_Cancelar` | Antes del despacho; reintegra existencia y libera el cupón | Cliente (solo el suyo en `PAGADO`) o `PEDIDOS_GESTIONAR` |
| `SP_Pedidos_RegistrarDevolucion` | Total o parcial por línea; reintegra al kardex | `PEDIDOS_GESTIONAR` |
| `SP_Pedidos_ListarTransiciones` | Transiciones válidas (para el frontend) | Público |

### 7. Dashboard, reportes y configuración (`025`)

| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Reportes_ResumenDashboard` | KPIs del periodo con comparación contra el anterior | `REPORTES_VER` |
| `SP_Reportes_VentasPorPeriodo` | Ventas por día, semana o mes (en Q y número de pedidos) | `REPORTES_VER` |
| `SP_Reportes_VentasPorCategoria` | Ventas netas y porcentaje por categoría | `REPORTES_VER` |
| `SP_Reportes_TopProductos` | Los 10 productos más vendidos (parametrizable) | `REPORTES_VER` |
| `SP_Reportes_CarritosAbandonados` | Carritos sin actividad en el periodo configurable | `REPORTES_VER` |
| `SP_Pedidos_Listar` | Listado con filtros por estado, cliente, texto y fechas | `PEDIDOS_GESTIONAR` o `REPORTES_VER` |
| `SP_Configuracion_Listar` / `Actualizar` | Offset de hora local y horas de abandono | `CONFIGURACION_GESTIONAR` |

### 9. Bitacora (`028`)
| Procedimiento | Propósito | Permiso |
|---|---|---|
| `SP_Bitacora_Listar` | Consulta con filtro por módulo, usuario y fechas | Administrador |
| `SP_Bitacora_Registrar`, `SP_Usuarios_ValidarAdministrador` | Auxiliares usados por los demás SPs | Interno a la capa de datos |

Todos los listados filtran, ordenan y paginan **en el servidor**.

## Tareas programadas (las ejecuta el backend)

Cada minuto, el backend debe invocar:

| Procedimiento | Efecto |
|---|---|
| `SP_Inventario_LiberarReservasVencidas` | Libera las reservas de 15 minutos vencidas, sin intervención manual |
| `SP_Checkout_ExpirarPagos` | Marca como `EXPIRADO` los pagos cuya reserva ya no está vigente |

Si el job se cae, el stock no queda bloqueado: `SP_Inventario_ReservarExistencia` libera antes las reservas vencidas de las variantes involucradas.

## Datos semilla

| Dato | Detalle |
|---|---|
| Roles y permisos | Cliente, Operador y Administrador con una matriz fija de 10 permisos |
| Catálogo | 8 categorías, 6 productos curados y 400 productos de prueba (1,200 variantes) |
| Cupones | `BIENVENIDA10`, `QUETZALES25`, `ROPA15`, `ULTIMOCUPON`, `VENCIDO5`, `PROXIMAMENTE` |
| Envíos | Recoger en tienda (Q0), estándar (Q35), express (Q60) |
| Usuario de sistema | `sistema@shopcart.local`, **inactivo y sin contraseña válida**; firma la carga inicial de stock |
| Clientes de demostración | `cliente01` a `cliente60@demo.shopcart.local`, sin contraseña válida (no inician sesión) |
| Volumen | 3,000 pedidos en 120 días en todos los estados, con historial, devoluciones y kardex; 18 carritos |

El primer **Administrador**, un Operador y un Cliente de prueba con contraseña real los crea el script de semillas del backend, porque requieren un hash generado por la aplicación.

Una de cada 7 variantes queda sin existencia y `TEN-DEP-42-BLA` queda con **1 unidad**, para probar la disponibilidad y la competencia por la última unidad.
