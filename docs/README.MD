# Diagrama entidad-relación — ShopCart

Modelo relacional de la base de datos `ShopCart` (SQL Server): **30 tablas** creadas con scripts SQL propios, sin ORM. El modelo se divide por dominios para que cada diagrama sea legible. Las tablas que aparecen en más de un diagrama se repiten solo con sus llaves.

Convenciones: `PK` llave primaria, `FK` llave foránea, `UK` restricción `UNIQUE`. Los nombres siguen el estándar del reto (`IDNombre` para llaves primarias autoincrementables).

> Todas las fechas se almacenan en UTC (`DATETIME2(0)`). Todos los montos son `DECIMAL`; no existe ningún `FLOAT` ni `REAL`.

## 1. Seguridad, bitácora y configuración

```mermaid
erDiagram
    Roles ||--o{ Usuarios : "asigna rol"
    Roles ||--o{ RolesPermisos : "concede"
    Permisos ||--o{ RolesPermisos : "pertenece a"
    Usuarios ||--o{ TokensRefresco : "sesiones"
    TokensRefresco |o--o| TokensRefresco : "reemplazado por"
    Usuarios ||--o{ Bitacora : "registra"

    Roles {
        int IDRol PK
        nvarchar Nombre UK
        bit Activo
    }
    Permisos {
        int IDPermiso PK
        nvarchar Codigo UK
    }
    RolesPermisos {
        int IDRol PK, FK
        int IDPermiso PK, FK
    }
    Usuarios {
        int IDUsuario PK
        int IDRol FK
        nvarchar Correo UK
        nvarchar PasswordHash
        bit Activo
    }
    TokensRefresco {
        bigint IDTokenRefresco PK
        int IDUsuario FK
        char TokenHash UK
        datetime2 FechaExpiracion
        datetime2 FechaRevocacion
        bigint IDTokenReemplazo FK
    }
    Bitacora {
        bigint IDBitacora PK
        int IDUsuario FK
        nvarchar Modulo
        nvarchar Entidad
        nvarchar Accion
        nvarchar ValorAnterior
        nvarchar ValorNuevo
    }
    Configuracion {
        nvarchar Clave PK
        nvarchar Valor
    }
    VersionesEsquema {
        int IDVersionEsquema PK
        nvarchar Script UK
    }
```

## 2. Catálogo e inventario

```mermaid
erDiagram
    Categorias ||--o{ Productos : "clasifica"
    Productos ||--o{ ImagenesProducto : "tiene"
    Productos ||--o{ Variantes : "se vende como"
    Variantes ||--o{ VarianteAtributos : "se describe con"
    Atributos ||--o{ VarianteAtributos : "define"
    Variantes ||--o{ MovimientosInventario : "kardex"
    Usuarios ||--o{ MovimientosInventario : "registra"
    Usuarios ||--o{ Reservas : "aparta"
    Reservas ||--o{ ReservasDetalle : "incluye"
    Variantes ||--o{ ReservasDetalle : "reservada en"

    Categorias {
        int IDCategoria PK
        nvarchar Nombre UK
        bit Activo
    }
    Productos {
        int IDProducto PK
        int IDCategoria FK
        nvarchar Nombre
        bit Activo
    }
    ImagenesProducto {
        int IDImagenProducto PK
        int IDProducto FK
        nvarchar Url
        bit EsPrincipal
    }
    Atributos {
        int IDAtributo PK
        nvarchar Nombre UK
    }
    Variantes {
        int IDVariante PK
        int IDProducto FK
        nvarchar SKU UK
        decimal Precio
        int ExistenciaFisica
        int ExistenciaReservada
        int ExistenciaDisponible
    }
    VarianteAtributos {
        int IDVariante PK, FK
        int IDAtributo PK, FK
        nvarchar Valor
    }
    MovimientosInventario {
        bigint IDMovimiento PK
        int IDVariante FK
        nvarchar TipoMovimiento
        int Cantidad
        int ExistenciaResultante
        nvarchar Motivo
        nvarchar TipoReferencia
        int IDReferencia
        int IDUsuario FK
    }
    Reservas {
        int IDReserva PK
        int IDUsuario FK
        nvarchar Estado
        datetime2 FechaVencimiento
    }
    ReservasDetalle {
        int IDReserva PK, FK
        int IDVariante PK, FK
        int Cantidad
    }
```

`ExistenciaDisponible` es una columna calculada (`ExistenciaFisica − ExistenciaReservada`). `ExistenciaFisica` siempre es igual a la suma de `MovimientosInventario.Cantidad` (ver `VW_Inventario_Conciliacion`).

## 3. Carrito y cupones

```mermaid
erDiagram
    Usuarios |o--o{ Carritos : "dueño (o invitado por token)"
    Carritos ||--o{ CarritosDetalle : "incluye"
    Variantes ||--o{ CarritosDetalle : "agregada en"
    Categorias |o--o{ Cupones : "aplica a"
    Cupones |o--o{ Carritos : "aplicado en"
    Cupones ||--o{ UsosCupones : "se consume en"
    Usuarios ||--o{ UsosCupones : "usa"
    Pedidos |o--o| UsosCupones : "genera"

    Carritos {
        int IDCarrito PK
        int IDUsuario FK
        char TokenHash UK
        nvarchar Estado
        int IDCupon FK
        datetime2 FechaActualizacion
    }
    CarritosDetalle {
        int IDCarrito PK, FK
        int IDVariante PK, FK
        int Cantidad
    }
    Cupones {
        int IDCupon PK
        nvarchar Codigo UK
        nvarchar TipoDescuento
        decimal Valor
        int IDCategoria FK
        decimal MontoMinimo
        datetime2 FechaInicio
        datetime2 FechaFin
        int LimiteUsosTotal
        int LimiteUsosPorCliente
        int UsosActuales
    }
    UsosCupones {
        int IDUsoCupon PK
        int IDCupon FK
        int IDUsuario FK
        int IDPedido FK
        decimal MontoDescuento
        nvarchar Estado
    }
```

Un carrito pertenece **exactamente** a un usuario o a un invitado (`CK_Carritos_Propietario`). De los tokens de invitado solo se guarda el hash.

## 4. Checkout, pedidos, pagos y devoluciones

```mermaid
erDiagram
    Usuarios ||--o{ Direcciones : "registra"
    Usuarios ||--o{ Pedidos : "compra"
    MetodosEnvio ||--o{ Pedidos : "envío elegido"
    Direcciones |o--o{ Pedidos : "origen de la copia"
    Cupones |o--o{ Pedidos : "descuento"
    Reservas |o--o| Pedidos : "consumida por"
    Pedidos ||--o{ DetallePedidos : "líneas"
    Variantes ||--o{ DetallePedidos : "vendida en"
    Pedidos ||--o{ HistorialEstadosPedido : "bitácora de estado"
    Usuarios ||--o{ HistorialEstadosPedido : "cambió"
    Usuarios ||--o{ Pagos : "paga"
    Carritos ||--o{ Pagos : "origen"
    Reservas |o--o{ Pagos : "protege existencias"
    Pedidos |o--o| Pagos : "resultado"
    Direcciones ||--o{ Pagos : "entrega"
    MetodosEnvio ||--o{ Pagos : "envío"
    Pedidos ||--o{ Devoluciones : "se devuelve"
    Usuarios ||--o{ Devoluciones : "registra"
    Devoluciones ||--o{ DetalleDevoluciones : "incluye"
    DetallePedidos ||--o{ DetalleDevoluciones : "línea devuelta"

    Direcciones {
        int IDDireccion PK
        int IDUsuario FK
        nvarchar Direccion
        bit EsPredeterminada
        bit Activo
    }
    MetodosEnvio {
        int IDMetodoEnvio PK
        nvarchar Nombre UK
        decimal Costo
    }
    Pedidos {
        int IDPedido PK
        int IDUsuario FK
        nvarchar Estado
        decimal Subtotal
        decimal Descuento
        decimal CostoEnvio
        decimal Total
        decimal BaseImponible
        decimal Iva
        int IDCupon FK
        int IDReserva FK
    }
    DetallePedidos {
        int IDDetallePedido PK
        int IDPedido FK
        int IDVariante FK
        nvarchar SKU
        decimal PrecioUnitario
        int Cantidad
        decimal Subtotal
        decimal DescuentoLinea
        int CantidadDevuelta
    }
    HistorialEstadosPedido {
        bigint IDHistorial PK
        int IDPedido FK
        nvarchar EstadoAnterior
        nvarchar EstadoNuevo
        int IDUsuario FK
        datetime2 Fecha
    }
    Pagos {
        int IDPago PK
        int IDUsuario FK
        nvarchar ClaveIdempotencia "UK con IDUsuario"
        int IDCarrito FK
        int IDReserva FK
        decimal Monto
        nvarchar Estado
        int IDPedido FK
    }
    Devoluciones {
        int IDDevolucion PK
        int IDPedido FK
        int IDUsuario FK
        nvarchar Motivo
        decimal MontoReembolso
    }
    DetalleDevoluciones {
        int IDDevolucion PK, FK
        int IDDetallePedido PK, FK
        int Cantidad
        decimal MontoReembolso
    }
    TransicionesEstadoPedido {
        nvarchar EstadoOrigen PK
        nvarchar EstadoDestino PK
    }
```

`TransicionesEstadoPedido` no tiene llaves foráneas: es la tabla de referencia contra la que el trigger `TR_Pedidos_ValidarTransicion` valida cada cambio de `Pedidos.Estado`.

## Integridad que el modelo impone por sí mismo

| Regla | Mecanismo |
|---|---|
| Nunca hay sobreventa | `CK_Variantes_Existencias`: `0 ≤ ExistenciaReservada ≤ ExistenciaFisica` |
| Un cupón no excede su límite total | `CK_Cupones_Usos`: `UsosActuales ≤ LimiteUsosTotal` |
| Un cupón por pedido | Índice único `UX_UsosCupones_Pedido` |
| Un pago (y un pedido) por solicitud | `UX_Pagos_Clave (IDUsuario, ClaveIdempotencia)` y `UX_Pagos_Pedido` |
| Una reserva activa por usuario | Índice único filtrado `UX_Reservas_UsuarioActiva` |
| Un carrito activo por usuario | Índice único filtrado `UX_Carritos_UsuarioActivo` |
| No se devuelve más de lo vendido | `CK_DetallePedidos_Devuelta`: `0 ≤ CantidadDevuelta ≤ Cantidad` |
| Los montos del pedido cuadran | `CK_Pedidos_Montos`: `Total = Subtotal − Descuento + CostoEnvio` y `Base + IVA = Total` |
| Precios y montos congelados | Triggers `TR_Pedidos_Congelado` y `TR_DetallePedidos_Congelado` |
| Solo transiciones de estado válidas | Trigger `TR_Pedidos_ValidarTransicion` + `TransicionesEstadoPedido` |
| Bitácora, kardex, historial y devoluciones inmutables | Triggers `INSTEAD OF UPDATE, DELETE` |
| Usuarios, pedidos y líneas no se eliminan | Triggers `INSTEAD OF DELETE` |