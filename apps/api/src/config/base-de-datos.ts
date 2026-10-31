
import sql from 'mssql';
import { env } from './env';

const configuracionBaseDatos: sql.config = {
    server: env.database.server,
    port: env.database.port,

    database: env.database.name,
    user: env.database.user,
    password: env.database.password,

    options: {
        encrypt: env.database.encrypt,
        trustServerCertificate: env.database.trustServerCertificate
    },

    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    },

    connectionTimeout: 15000,
    requestTimeout: 30000
};

let promesaConexion: Promise<sql.ConnectionPool> | null = null;

export const obtenerConexion = async (): Promise<sql.ConnectionPool> => {
    if (!promesaConexion) {
        const conexion = new sql.ConnectionPool(configuracionBaseDatos);

        promesaConexion = conexion.connect().catch((error: unknown) => {
            promesaConexion = null;
            throw error;
        });
    }

    return promesaConexion;
};

export const cerrarConexion = async (): Promise<void> => {
    if (promesaConexion) {
        const conexion = await promesaConexion;
        await conexion.close();
        promesaConexion = null;
    }
};
