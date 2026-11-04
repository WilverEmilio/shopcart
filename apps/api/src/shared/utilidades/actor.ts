import type { Request } from 'express';
import { ErrorAplicacion } from '../errores/error-aplicacion';

export const obtenerIdActor = (req: Request): number => {
    const idUsuario = req.usuarioAutenticado?.idUsuario;

    if (!idUsuario) {
        throw new ErrorAplicacion(
            'Debes iniciar sesión para acceder a este recurso', 
            40100, 
            401
        );
    }

    return idUsuario;
};