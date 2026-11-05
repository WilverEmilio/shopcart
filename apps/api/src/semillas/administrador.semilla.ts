import bcrypt from 'bcrypt';
import sql from 'mssql';

import { env } from '../config/env';
import { ejecutarProcedimiento } from '../shared/base_de_datos/ejecutar-procedimiento';

const RONDAS_BCRYPT = 10;

interface ResultadoAdministradorSemilla {
    IDUsuario: number;
    Creado: boolean;
}

export const crearAdministradorSemilla = async (): Promise<number> => {
    const correo = env.database.adminSeedCorreo?.trim().toLowerCase();
    const contrasena = env.database.adminSeedContrasena;
    const nombres = env.database.adminSeedNombres?.trim();
    const apellidos = env.database.adminSeedApellidos?.trim();

    if (!correo || !contrasena || !nombres || !apellidos) {
        throw new Error(
            'Faltan variables de entorno para crear el administrador semilla.'
        );
    }

    const passwordHash = await bcrypt.hash(contrasena, RONDAS_BCRYPT);

    const resultado = await ejecutarProcedimiento<ResultadoAdministradorSemilla>(
        'dbo.SP_Usuarios_CrearAdministradorSemilla',
        (solicitud) => {
            solicitud.input('Correo', sql.NVarChar(255), correo);
            solicitud.input('PasswordHash', sql.NVarChar(255), passwordHash);
            solicitud.input('Nombres', sql.NVarChar(100), nombres);
            solicitud.input('Apellidos', sql.NVarChar(100), apellidos);
        }
    );

    const administrador = resultado.recordset[0];

    if (!administrador) {
        throw new Error(
            'No se pudo confirmar la creación del administrador semilla.'
        );
    }

    if (administrador.Creado) {
        console.log(
            `Administrador semilla creado. ID: ${administrador.IDUsuario}`
        );
    } else {
        console.log(
            `El administrador semilla ya existía. ID: ${administrador.IDUsuario}`
        );
    }

    return administrador.IDUsuario;
};