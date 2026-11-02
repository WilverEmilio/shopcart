import sql from 'mssql'
import { ejecutarProcedimiento } from '../../../shared/ejecutar-procedimiento'
import type { 
    UsuarioBaseDatos, 
    DatosRegistroCliente,  
    UsuarioDetalleBaseDatos,
    UsuarioTokenBaseDatos,
    TokenGuardadoBaseDatos
} from '../tipos/usuario.tipo'

export const obtenerUsuariosPorCorreo = async (
    correo: string
): Promise<UsuarioBaseDatos | null> => {
    const resultado = await ejecutarProcedimiento<UsuarioBaseDatos>(
        'dbo.SP_Usuarios_ObtenerPorCorreo', 
        (solicitud) => {
            solicitud.input('Correo', sql.NVarChar(255), correo)
        }
    );

    return resultado.recordset[0] ?? null;
}

export const registrarCliente = async (
    datos: DatosRegistroCliente
): Promise<number> => {
    const resultado = await ejecutarProcedimiento<{ IDUsuario: number}>(
        'dbo.SP_Usuarios_RegistrarCliente', 
        (solicitud) => {
            solicitud.input('Correo', sql.NVarChar(255), datos.correo);
            solicitud.input('PasswordHash', sql.NVarChar(255), datos.passwordHash);
            solicitud.input('Nombres', sql.NVarChar(100), datos.nombres);
            solicitud.input('Apellidos', sql.NVarChar(100), datos.apellidos);
            solicitud.input('Telefono', sql.NVarChar(20), datos.telefono);
        }
    );

    return resultado.recordset[0].IDUsuario;
} 

export const obtenerUsuarioPorID = async (
    idUsuario: number
): Promise<UsuarioDetalleBaseDatos | null> => {
    const resultado = await ejecutarProcedimiento<UsuarioDetalleBaseDatos>(
        'dbo.SP_Usuarios_ObtenerPorID',
        (solicitud) => {
            solicitud.input('IDUsuario', sql.Int, idUsuario)
        }  
    );

    return resultado.recordset[0] ?? null;
}

export const guardarTokenRegresco = async (
    idUsuario: number, 
    tokernHash: string,
    fechaExpiracion: Date
): Promise<number> => {
    const resultado = await ejecutarProcedimiento<TokenGuardadoBaseDatos>(
        'dbo.SP_Tokens_Guardar',
        (solicitud) => {
            solicitud.input('IDUsuario', sql.Int, idUsuario);
            solicitud.input('TokenHash', sql.Char(64), tokernHash);
            solicitud.input('FechaExpiracion', sql.DateTime2, fechaExpiracion)
        }
    ); 

    return resultado.recordset[0].IDTokenRefresco;
}

export const rotarTokernRegresco = async (
    tokernHashActual: string,
    tokenHasNuevo: string,
    fechaExpiracionNueva: Date 
): Promise<UsuarioTokenBaseDatos | null> => {
    const resultado = await ejecutarProcedimiento<UsuarioTokenBaseDatos>(
        'dbo.SP_Tokens_Rotar',
        (solicitud) => {
            solicitud.input('TokenHashActual', sql.Char(64), tokernHashActual);
            solicitud.input('TokenHashNuevo', sql.Char(64), tokenHasNuevo);
            solicitud.input('FechaExpiracionNueva', sql.DateTime2, fechaExpiracionNueva);
        }
    ); 

    return resultado.recordset[0] ?? null;
}

export const revocarTokenRefresco = async (
    tokenHash: string
): Promise<void> => {
    await ejecutarProcedimiento<void>(
        'dbo.SP_Tokens_Revocar', 
        (solicitud) => {
            solicitud.input('TokenHash', sql.Char(64), tokenHash);
        }
    );
}