## Credenciales de acceso de prueba

### Administrador

- **Correo:** `admin@shopcart.local`
- **Contraseña:** `AdminShopCart2026!`
- **Rol:** Administrador

El correo, la contraseña van en el .env, asi mismo poner cualquier nombres y apellidos

El usuario administrador se crea automáticamente durante la inicialización del backend, siempre que todavía no exista en la base de datos.

La contraseña se almacena utilizando **bcrypt**, por lo que no se guarda en texto plano.

Estas credenciales pueden utilizarse para probar el inicio de sesión y las funcionalidades protegidas que requieren permisos de administrador.

**Consideraciones:**
- Son credenciales destinadas únicamente a pruebas y desarrollo local.
- Si no puedes iniciar sesión, verifica que el backend se haya inicializado correctamente y que el usuario exista en la base de datos.
- No utilices estas credenciales en un entorno de producción.

## Pruebas de endpoints con Postman

El proyecto incluye una colección de Postman con los endpoints del backend, que permite probar las funcionalidades de la API.

### Importar la colección

1. Abre Postman.
2. Selecciona **Import**.
3. Selecciona el archivo `postman/ShopCart.postman_collection.json`.
4. Espera a que Postman cargue las solicitudes.

### Configurar la autenticación

Algunos endpoints requieren autenticación mediante un token JWT de acceso.

Para obtenerlo:

1. Ejecuta la solicitud de **inicio de sesión** (`login`) utilizando las credenciales de un usuario registrado.
2. Copia el token de acceso que devuelve la respuesta de la API.
3. Abre la solicitud que deseas probar y selecciona la pestaña **Authorization**.
4. En **Auth Type**, selecciona **Bearer Token**.
5. Pega el token de acceso en el campo **Token**.
6. Ejecuta la solicitud.

Postman enviará automáticamente el token en la cabecera:

`Authorization: Bearer <token>`

### Rutas públicas y protegidas

- **Rutas públicas:** pueden ejecutarse sin proporcionar un token de autenticación. Por ejemplo, el inicio de sesión.
- **Rutas protegidas:** requieren un token JWT de acceso válido.
- **Rutas administrativas:** además de requerir autenticación, necesitan que el usuario tenga el rol de Administrador.

Si el token ha expirado, debes iniciar sesión nuevamente y utilizar el nuevo token de acceso.

### Consideraciones

- Utiliza el token de acceso, no el refresh token.
- No compartas ni publiques tokens reales.
- Algunas solicitudes requieren datos previamente registrados en la base de datos.
- Los permisos dependen del rol y de las reglas de autorización implementadas en cada endpoint.