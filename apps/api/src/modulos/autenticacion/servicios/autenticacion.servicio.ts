import bcrypt from 'bcrypt'; 
import jwt from 'jsonwebtoken';
import {createHash, randomBytes} from 'crypto';
import {env} from '../../../config/env'; 

import {
    obtenerUsuariosPorCorreo,
    registrarCliente, 
    guardarTokenRegresco,
    rotarTokenRefresco
} from '../repositorios/autenticacion.repositorio';

import type {
    CredencialesAcceso,
    DatosRegistroCliente,
} from '../tipos/usuario.tipo';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';

const RONDAS_BCRYPT = 10;
const HASH_FALSO = bcrypt.hashSync('contrasena-falsa-ShopCart', RONDAS_BCRYPT);
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
            algorithm: 'HS256',
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

    fecha.setUTCDate(
        fecha.getUTCDate() + env.seguridad.expiracionRefreshDias
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
    const correo = credenciales.correo.trim().toLowerCase();
    const usuario = await obtenerUsuariosPorCorreo(correo);

    const sontrasenaValida = await bcrypt.compare(
        credenciales.contrasena,
        usuario?.PasswordHash ?? HASH_FALSO
    ); 
    if (!usuario || !usuario.Activo){
        throw new ErrorAplicacion(
            'Correo o contraseña incorrectos',
            40100,
            401
        )
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
            correo: usuario.Correo,
            nombres: usuario.Nombres,
            apellidos: usuario.Apellidos,
            rol: usuario.Rol
        },
        tokenAcceso,
        tokenRefresco
    };
};

export const renovarToken = async (
    tokenRefresco: string
)=> {
    if(!tokenRefresco || typeof tokenRefresco !== 'string') {
        throw new ErrorAplicacion(
            'Debes proporcionar un token de refresco', 
            40100, 
            401
        );
    }

    const tokenHashActual = calularHashToken(tokenRefresco);
    const nuevoTokenRefresco = generarTokenRefresco();
    const tokenHashNuevo = calularHashToken(nuevoTokenRefresco);
    const fechaExpiracionNueva = calcularFechaExpiracionTokenRefresco();

    const usuario = await rotarTokenRefresco(
        tokenHashActual,
        tokenHashNuevo,
        fechaExpiracionNueva
    )

    if(!usuario){
        throw new ErrorAplicacion(
            'No fue posible renovar sesión',
            40100, 
            401
        );
    }

    const tokenAcceso = generarTokenAcceso(
        usuario.IDUsuario,
        usuario.Correo,
        usuario.Rol
    );

    return {
        usuario: {
            idUsuario: usuario.IDUsuario,
            correo: usuario.Correo,
            rol: usuario.Rol
        },
        tokenAcceso,
        tokenRefresco: nuevoTokenRefresco
    };
};