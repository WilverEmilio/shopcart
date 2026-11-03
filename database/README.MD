# ShopCart — Base de datos

Base de datos relacional del proyecto **ShopCart**, desarrollada en Microsoft SQL Server. Contiene la estructura de datos, reglas de negocio, procedimientos almacenados y datos de prueba necesarios para el funcionamiento de la aplicación.

El acceso a los datos se realiza exclusivamente mediante **procedimientos almacenados (Stored Procedures)**. No se utiliza ningún ORM ni se ejecutan consultas SQL directamente desde el backend.

## Requisitos

Antes de instalar la base de datos, asegúrate de contar con lo siguiente:

- Microsoft SQL Server 2019 o superior.
- SQL Server Management Studio (SSMS), Azure Data Studio o la utilidad `sqlcmd`.
- Un usuario de SQL Server con permisos para crear y modificar bases de datos y sus objetos.

## Instalación

Para instalar la base de datos de ShopCart, sigue estos pasos:

### 1. Ubicar los scripts

Dentro de esta carpeta encontrarás el directorio:

```text
Scripts_Completos/
```

Este directorio contiene los tres archivos SQL necesarios para crear y configurar la base de datos.

### 2. Ejecutar los scripts en orden

Abre SQL Server Management Studio (SSMS) y conéctate a tu instancia de SQL Server.

Ejecuta los tres archivos SQL de la carpeta `Scripts_Completos` **uno por uno y respetando estrictamente el siguiente orden**:

| Orden | Script | Descripción |
|---|---|---|
| 1 | Script de tablas | Crea la base de datos y las tablas, relaciones, restricciones y demás estructuras necesarias. |
| 2 | Script de procedimientos | Crea los procedimientos almacenados y demás objetos programables requeridos por la aplicación. |
| 3 | Script de semillas | Inserta los datos iniciales y registros de prueba necesarios para utilizar el sistema. |

**Importante:** espera a que cada script termine de ejecutarse correctamente antes de continuar con el siguiente. No cambies el orden, ya que los procedimientos dependen de las tablas y los datos semilla dependen de los objetos previamente creados.

### 3. Verificar la instalación

Cuando los tres scripts hayan finalizado correctamente, actualiza la lista de bases de datos en SSMS y verifica que la base de datos `ShopCart` esté disponible.

También puedes ejecutar:

```sql
SELECT name
FROM sys.databases
WHERE name = 'ShopCart';
```

Si la consulta devuelve `ShopCart`, la base de datos se encuentra creada.

## Estructura y características

La base de datos está organizada por módulos funcionales que cubren las principales operaciones de una tienda en línea:

| Módulo | Descripción |
|---|---|
| Seguridad | Usuarios, roles, permisos, autenticación y bitácora. |
| Catálogo | Categorías, productos, imágenes, atributos y variantes. |
| Inventario | Existencias, movimientos, reservas y kardex. |
| Carrito | Gestión de carritos, productos y cantidades. |
| Cupones | Administración, validación y cálculo de descuentos. |
| Checkout | Direcciones, métodos de envío y proceso de pago. |
| Pedidos | Creación, seguimiento, cancelaciones y devoluciones. |
| Reportes | Indicadores, estadísticas y dashboard administrativo. |

### Características técnicas

- **Motor de base de datos:** Microsoft SQL Server 2019 o superior.
- **Lenguaje:** T-SQL.
- **Acceso a datos:** procedimientos almacenados.
- **Seguridad:** usuarios, roles y permisos definidos en la base de datos.
- **Integridad:** llaves primarias, llaves foráneas, restricciones y transacciones.
- **Auditoría:** registro de operaciones relevantes mediante bitácora.
- **Datos de prueba:** registros semilla para facilitar las pruebas y demostraciones.

## Seguridad y acceso desde la aplicación

La aplicación utiliza un usuario específico de base de datos denominado `shopcart_app`, asociado al rol `RolShopCartApp`.

Este usuario cuenta con permisos limitados para ejecutar los procedimientos almacenados autorizados del esquema `dbo`. No debe utilizarse el usuario administrador de SQL Server (`sa`) desde el backend.

El objetivo es mantener las operaciones de lectura y escritura controladas desde la propia base de datos, reforzando la seguridad y la integridad de la información.

## Datos semilla

El tercer script incorpora los datos iniciales necesarios para probar los módulos de la aplicación, incluyendo información de catálogo, roles, permisos y registros de demostración.

Estos datos permiten contar con una base inicial para realizar pruebas funcionales sin tener que ingresar manualmente toda la información.

## Consideraciones importantes

- Ejecutar los tres scripts en el orden indicado.
- No ejecutar los scripts de forma simultánea.
- Verificar que cada ejecución finalice sin errores.
- No utilizar credenciales administrativas de SQL Server en la configuración del backend.
- Si necesitas reiniciar la instalación desde cero, asegúrate de revisar primero qué información se eliminará, ya que los scripts pueden crear o modificar objetos y datos existentes.

---

**ShopCart — Base de datos**  
Proyecto de tienda en línea desarrollado con fines académicos y de demostración.