# ShopCart · Frontend

Aplicación web de ShopCart (tienda y paneles de gestión). React + TypeScript + Vite + Tailwind CSS.

← [Volver al README principal](../../README.md) · API: [`apps/api/README.md`](../api/README.md)

## Requisitos

- Node.js 24 o superior
- La API en marcha (ver [`apps/api/README.md`](../api/README.md))
- Ejecutar backend, asi mismo volver a correr todos los scripts, ya que se agregaron más procedimientos almacenados para su funcionamiento.

## Instalación y scripts

```bash
cp .env.example .env
npm install
npm run dev              # http://localhost:5173
```

| Script | Qué hace |
|---|---|
| `npm run dev` | Servidor de desarrollo con recarga |
| `npm run build` | Verifica tipos (`tsc -b`) y genera `dist/` |
| `npm run preview` | Sirve la compilación de `dist/` |
| `npm run lint` | ESLint (debe terminar sin errores) |

## Variables de entorno

| Variable | Descripción |
|---|---|
| `VITE_API_URL` | URL base de la API. Por defecto `http://localhost:3000/api` | VITE_APP_NAME=ShopCart
| `VITE_APP_NAME` | Nombre de la pagina web. |

## Librerías

| Necesidad | Librería |
|---|---|
| Rutas | `react-router-dom` |
| Datos del servidor (caché, paginación, estados) | `@tanstack/react-query` |
| Estado global (sesión, carrito de invitado, checkout) | `zustand` |
| Formularios y validación | `react-hook-form` + `zod` |
| HTTP | `axios` |
| Gráficas | `recharts` |
| Estilos | Tailwind CSS |

## Estructura

```text
src/
├── componentes/     # piezas reutilizables: Boton, CampoFormulario, Modal, DialogoConfirmacion,
│                    # Paginador, EstadoCarga / EstadoVacio / EstadoError, BloqueConsulta,
│                    # ImagenProducto, LimiteDeError, PaginaNoEncontrada
├── configuracion/   # entorno, cliente de React Query, zod en español
├── diseños/         # DisenoPrincipal: cabecera, menú por rol y límite de errores
├── estados/         # stores de Zustand: sesionEstado, carritoEstado, checkoutEstado
├── hooks/           # useParametrosUrl (filtros guardados en la URL)
├── rutas/           # AppRouter y RutasProtegidas
├── servicios/       # clienteHttp (axios + renovación de token) y errorServicio
├── tipos/           # tipos compartidos (usuario, respuesta de la API, errores)
├── utilidades/      # formato (moneda, fechas), formularios, rutas por rol
└── modulos/
    └── <modulo>/    # tipos · servicios · hooks · esquemas · componentes · paginas
```

Módulos: `autenticacion`, `catalogo`, `carrito`, `direcciones`, `checkout`, `pedidos`, `inventario`, `catalogoAdmin`, `cupones`, `usuarios`, `reportes` y `bitacora`.

## Arquitectura de un módulo

```text
página  →  hook (React Query)  →  servicio (axios)  →  API
  │              │
  │              └── caché, estados de carga y error, invalidación tras cambios
  └── componentes del módulo (presentación)
```

- **Servicios**: una función por endpoint, solo HTTP. Sin lógica de interfaz.
- **Hooks**: envuelven consultas y mutaciones; cada mutación invalida las consultas afectadas.
- **Páginas y componentes**: presentan datos y reúnen interacción. Las reglas de negocio viven en el backend y en la base de datos.
- **Tipos**: espejo de las respuestas de la API (siempre en `camelCase`).

## Estado

| Tipo | Dónde vive |
|---|---|
| Datos del servidor | TanStack Query (caché, `keepPreviousData` al paginar, consultas habilitadas solo cuando la sesión se restauró) |
| Sesión (usuario y tokens) | `sesionEstado`; solo el refresh token se persiste (`localStorage`) |
| Carrito de invitado | `carritoEstado`; persiste el token del carrito |
| Intento de pago | `checkoutEstado` en `sessionStorage` (clave de idempotencia, selección y pago iniciado) |
| Filtros, orden y página de las tablas | La **URL** (`useParametrosUrl`): se pueden compartir y el botón "atrás" funciona |

## Autenticación

1. `iniciarSesion` guarda el access token en memoria y el refresh token en `localStorage`.
2. `clienteHttp` agrega `Authorization` a cada solicitud.
3. Si una respuesta es **401**, el interceptor renueva el token y repite la solicitud original. La renovación es **single-flight**: varias solicitudes simultáneas comparten una sola llamada, porque con rotación reusar un refresh ya rotado cerraría todas las sesiones.
4. Al abrir la app, `restaurarSesion` recupera la sesión una sola vez (a prueba de StrictMode).
5. Al iniciar sesión se **fusiona** el carrito de invitado con el de la cuenta antes de guardar la sesión.
6. Al cambiar de usuario se limpia la caché de consultas y el intento de pago.

## Rutas y roles

| Rol | Rutas |
|---|---|
| Público | `/` (redirige a `/catalogo`), `/catalogo`, `/catalogo/:idProducto`, `/carrito`, `/iniciar-sesion`, `/registro` |
| Cliente | `/mis-pedidos`, `/mis-pedidos/:idPedido`, `/checkout`, `/checkout/confirmacion` |
| Operador y Administrador | `/gestion/pedidos`, `/gestion/pedidos/:idPedido`, `/gestion/inventario`, `/gestion/inventario/kardex`, `/gestion/inventario/conciliacion` |
| Administrador | `/admin/dashboard`, `/admin/categorias`, `/admin/productos`, `/admin/productos/nuevo`, `/admin/productos/:idProducto`, `/admin/cupones`, `/admin/usuarios`, `/admin/bitacora` |

Las rutas protegidas usan `RutasProtegidas` (redirige a login si no hay sesión y a `/sin-permiso` si el rol no corresponde). El menú se arma según el rol en `DisenoPrincipal`. Una dirección inexistente muestra la página 404. **El control real está en la API**: el front solo oculta lo que no corresponde.

## Formularios y validación

- Validación con **zod** antes de enviar, con mensajes en español (`configuracion/zod.ts`).
- Los errores de campo que devuelve la API (`detalles`) se muestran bajo el campo correspondiente (`erroresPorCampo`).
- Formularios estáticos (acceso, registro, direcciones): `react-hook-form` + `zod`.
- Formularios dinámicos del administrador (variantes con atributos, imágenes, cupones): estado controlado + `safeParse` de zod con un mapa de errores por ruta (`variantes.0.sku`).

## Estados de la interfaz

Todas las vistas con datos muestran **carga**, **vacío** y **error** (con botón "Reintentar") mediante `EstadoCarga`, `EstadoVacio`, `EstadoError` y `BloqueConsulta`. Un `LimiteDeError` evita que una excepción de renderizado deje la pantalla en blanco.

## Interfaz responsive y accesibilidad

- Rejillas y menú plegable adaptables; las tablas hacen scroll horizontal dentro de su contenedor.
- Modales con `<dialog>` nativo (foco y tecla Esc), etiquetas asociadas a los campos y mensajes con `role="alert"` o `role="status"`.
- Las gráficas llevan una descripción accesible (`aria-label`).

## Rendimiento

Las pantallas de administración y gestión se cargan **bajo demanda** (`React.lazy`), así que la tienda del cliente descarga mucho menos código. La librería de gráficas solo se descarga al abrir el dashboard.

## Calidad

```bash
npm run lint && npm run build
```
El proyecto compila en modo estricto y pasa ESLint sin errores.

## Cómo agregar una pantalla

1. Tipos y **servicio** del endpoint en `modulos/<modulo>/`.
2. **Hook** con `useQuery` o `useMutation` (e invalidación de las consultas afectadas).
3. **Página** usando `BloqueConsulta` o los tres estados, y `Paginador` si lista datos.
4. Ruta en `rutas/AppRouter.tsx` dentro del bloque de `RutasProtegidas` que corresponda y, si debe verse en el menú, entrada en `configuracion/menu.ts`.

## Decisiones y trade-offs

- **Refresh token en `localStorage`**: simple, pero expuesto a XSS. Mitigaciones: access token solo en memoria y `helmet` en la API. Alternativa: cookie `httpOnly`.
- **Pasarela simulada**: la interfaz ofrece tres resultados de prueba en lugar de campos de tarjeta, para que los datos de tarjeta nunca pasen por el servidor.
- **Sin lógica de negocio en el front**: totales, descuentos, reservas y permisos los decide siempre la API.