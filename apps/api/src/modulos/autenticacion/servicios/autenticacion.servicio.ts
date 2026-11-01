import bcrypt from 'bcrypt'; 
import jwt from 'jsonwebtoken';
import {createHash, randomBytes} from 'crypto';
import {env} from '../../../config/env'; 

import {
    obtenerUsuariosPorCorreo,
    registrarCliente, 
    guardarTokenRegresco,
} from '../repositories/autenticacion.repositorio';

import type {
    CredencialesAcceso,
    DatosRegistroCliente
} from '../tipos/usuario.tipo';

const RONDAS_BCRYPT = 10;

const generarTokenAcceso = (
    idUsuario: number, 
    correo: string,
    rol: string    
): string => {
    return jwt.sign(
        {
            correo,
            rol
        },
        env.seguridad.secretoJWT,{
            subject: String(idUsuario),
            expiresIn: env.seguridad.expiracionJWT as jwt.SignOptions['expiresIn']
        }
    );
};

const generarTokenRefresco = (): string => {
    return randomBytes(32).toString('hex');
};

const calularHashToken = (token: string): string => {
    return createHash('sha256')
    .update(token)
    .digest('hex');
}

const calcularFechaExpiracionTokenRefresco = (): Date => {
    const fecha = new Date();

    fecha.setDate(
        fecha.getDate() + env.seguridad.expiracionRefreshDias
    ); 
    return fecha;
}

export const registrarNuevoCliente = async (
    datos: Omit<DatosRegistroCliente, 'passwordHash'> & {
        contrasena: string
    }
): Promise<{idUsuario: number}> => {
    const passwordHash = await bcrypt.hash(
        datos.contrasena,
        RONDAS_BCRYPT
    );

    const idUsuario = await registrarCliente({
        correo: datos.correo,
        passwordHash,
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        telefono: datos.telefono
    });

    return {idUsuario};
}

export const iniciarSesion = async (
    credenciales: CredencialesAcceso
) => {
    const usuario = await obtenerUsuariosPorCorreo(credenciales.correo);
    if (!usuario || !usuario.Activo){
        throw new Error('Correo o contraseña incorrectas');
    }

    const contrasenaValida = await bcrypt.compare(
        credenciales.contrasena,
        usuario.PasswordHash
    );

    if(!contrasenaValida) {
        throw new Error('Correo o contraseña incorrectas');
    }

    const tokenAcceso = generarTokenAcceso(
        usuario.IDUsuario,
        usuario.Correo,
        usuario.Rol
    );

    const tokenRefresco = generarTokenRefresco();

    const hashTokenRefresco = calularHashToken(tokenRefresco);

    const fechaExpiracion = calcularFechaExpiracionTokenRefresco();

    await guardarTokenRegresco(
        usuario.IDUsuario,
        hashTokenRefresco,
        fechaExpiracion
    );

    return {
        usuario: {
            idUsuario: usuario.IDUsuario,
            ccorreo: usuario.Correo,
            nombres: usuario.Nombre,
            apellidos: usuario.Apellidos,
            rol: usuario.Rol
        },
        tokenAcceso,
        tokenRefresco
    };
};