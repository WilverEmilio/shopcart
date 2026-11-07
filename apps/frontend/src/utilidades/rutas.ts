import type { RolUsuario } from "../tipos/usuario";

export function rutaInicialPorRol(rol: RolUsuario): string {
    switch (rol) {
        case 'Administrador':
            return '/admin/dashboard';
        case 'Operador':
            return '/gestion/pedidos';
        default:
            return '/';
    }
}
