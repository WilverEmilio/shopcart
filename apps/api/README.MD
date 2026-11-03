## Credenciales de acceso de prueba

### Administrador

- **Correo:** `admin@shopcart.local`
- **Contraseña:** `AdminShopCart2026!`
- **Rol:** Administrador

El usuario administrador se crea automáticamente durante la inicialización del backend, siempre que todavía no exista en la base de datos.

La contraseña se almacena utilizando **bcrypt**, por lo que no se guarda en texto plano.

Estas credenciales pueden utilizarse para probar el inicio de sesión y las funcionalidades protegidas que requieren permisos de administrador.

**Consideraciones:**
- Son credenciales destinadas únicamente a pruebas y desarrollo local.
- Si no puedes iniciar sesión, verifica que el backend se haya inicializado correctamente y que el usuario exista en la base de datos.
- No utilices estas credenciales en un entorno de producción.