import { Request, Response, NextFunction } from "express";
import { ErrorAplicacion } from "../errores/error-aplicacion";
type RolUsuario = 'Cliente' | 'Operador' | 'Administrador';

export const autorizarRoles = (...rolesPermitidos: RolUsuario[])  => {
    return (
        solicitud: Request,
        _respusta: Response,
        siguiente: NextFunction
    ): void  => {
        const usuario = solicitud.usuarioAutenticado;

        if(!usuario) {
            siguiente(
                new ErrorAplicacion(
                    'Debes iniciar sesión para acceder a este recurso', 
                    40100,
                    401
                )
            );
            return;
        }
        if (!rolesPermitidos.includes(usuario.rol as RolUsuario)){
            siguiente(
                new ErrorAplicacion(
                    'No tienes permisos para realizar está acción',
                    40300, 
                    403
                )
            );
            return;
        }
        siguiente();
    }
}