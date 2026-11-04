import type { NextFunction, Request, Response } from 'express';
import {
    registrarNuevoCliente,
    iniciarSesion,
    renovarToken,
    cerrarSesion,
    obtenerPerfil
}from '../servicios/autenticacion.servicio'
import type {
    CredencialesAcceso,
    DatosRegistroCliente
} from '../tipos/usuario.tipo';

export const registrarClienteControlador = async (
    solicitud: Request,
    respuesta: Response,
    siguiente: NextFunction
): Promise<void> => {
    try {
        const resultado = await registrarNuevoCliente(solicitud.body);
        respuesta.status(201).json({
            mensaje: 'Cliente registrado exitosamente',
            datos: resultado
        });
    } catch (error) {
        siguiente(error);
    }
}; 

export const iniciarSesionControlador = async (
    solicitud: Request<{}, unknown, CredencialesAcceso>,
    respuesta: Response,
    siguiente: NextFunction
): Promise<void> => {
    try {
        const resultado = await iniciarSesion(solicitud.body);
        respuesta.status(200).json({
            mensaje: 'Inicio de sesión exitoso', 
            datos: resultado
        });
    } catch (error) {
        siguiente(error);
    }
};

export const renovarTokenControlador = async (
    solicitud: Request<
        {},
        unknown,
        { tokenRefresco: string }
    >,
    respuesta: Response,
    siguiente: NextFunction
): Promise<void> =>{
    try{
        const resultado = await renovarToken(
            solicitud.body.tokenRefresco
        );
        respuesta.status(200).json({
            mensaje: 'Token renovado exitosamente',
            datos: resultado
        });
    } catch (error) {
        siguiente(error);
    }
}
export const cerrarSesionControlador = async (solicitud: Request, respuesta: Response, siguiente: NextFunction): Promise<void> => {
    try {
        await cerrarSesion(solicitud.body.tokenRefresco);
        respuesta.status(200).json({ mensaje: 'Sesión cerrada correctamente' });
    } catch (error) { siguiente(error); }
};

export const obtenerPerfilControlador = async (solicitud: Request, respuesta: Response, siguiente: NextFunction): Promise<void> => {
    try {
        const datos = await obtenerPerfil(solicitud.usuarioAutenticado!.idUsuario);
        respuesta.status(200).json({ mensaje: 'Perfil obtenido correctamente', datos });
    } catch (error) { siguiente(error); }
};
