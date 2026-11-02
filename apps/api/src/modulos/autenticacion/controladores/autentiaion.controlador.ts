import type { NextFunction, Request, Response } from 'express';
import {
    registrarNuevoCliente,
    iniciarSesion,
}from '../servicios/autenticacion.servicio'
import type {
    CredencialesAcceso,
    DatosRegistroCliente
} from '../tipos/usuario.tipo';

export const registrarClienteControlador = async (
    solicitud: Request<
        {},
        unknown,
        Omit<DatosRegistroCliente, 'passwordHash'> & {
            contrasena: string
        }
    >,
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