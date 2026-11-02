import { Request, Response, NextFunction } from "express";
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { ErrorAplicacion } from "../errores/error-aplicacion";
import { DatosToken } from "../../modulos/autenticacion/tipos/usuario.tipo";

export const autenticar = (
    solicitud: Request,
    _respuesta: Response,
    siguiente: NextFunction
): void => {
    const encabezadoAutorizacion = solicitud.headers.authorization;
    
    if (!encabezadoAutorizacion || 
        !encabezadoAutorizacion.startsWith('Bearer ')) {
            siguiente(
                new ErrorAplicacion(
                    'Se requeire un token de acceso', 
                    40100,
                    401
                )
            );
            return;
    }

    const token = encabezadoAutorizacion.slice(7).trim();

    if(!token) {
        siguiente(
            new ErrorAplicacion(
                'El token de acceso no es válido',
                40100,
                401
            )
        );
        return;
    }

    try {
        const contenidoToken = jwt.verify(
            token,
            env.seguridad.secretoJWT
        );
        if (typeof contenidoToken === 'string' || 
            !contenidoToken.sub || 
            typeof contenidoToken.correo !== 'string' ||
            typeof contenidoToken.rol !== 'string' ) {
                throw new Error('Contenido del token inválido');
        }
        const idUsuario = Number(contenidoToken.sub);
        if(!Number.isSafeInteger(idUsuario)|| idUsuario <= 0){
            throw new Error('Identificador de usuario inválido');
        }
        const datosUsuario: DatosToken = {
            idUsuario,
            correo: contenidoToken.correo,
            rol: contenidoToken.rol
        };
        solicitud.usuarioAutenticado = datosUsuario;

        siguiente();
    } catch {
        siguiente(
            new ErrorAplicacion(
                'El token de acceso es inválido o ha expirado', 
                40110, 
                401
            )
        );
    }
};