
import dotenv from 'dotenv';

dotenv.config();

const puertoBaseDatos = Number(process.env.DB_PORT ?? 1433);
const puertoAplicacion = Number(process.env.PORT ?? 3000);

const secretoJWT = process.env.JWT_SECRETO;
const expiracionJWT = process.env.JWT_EXPIRACION ?? '15m';
const expiracionRefreshDias = Number(
    process.env.JWT_REFRESH_EXPIRACION_DIAS ?? 7
);

const variablesObligatorias = [
    'DB_SERVER',
    'DB_DATABASE',
    'DB_USER',
    'DB_PASSWORD',
    'JWT_SECRETO'
];

for (const variable of variablesObligatorias) {
    if (!process.env[variable]) {
        throw new Error(
            `Falta una variable de entorno obligatoria: ${variable}`
        );
    }
}

if (!Number.isInteger(puertoBaseDatos) ||
    puertoBaseDatos <= 0 ||
    puertoBaseDatos > 65535) {
    throw new Error('DB_PORT debe ser un puerto válido');
}

if (!Number.isInteger(puertoAplicacion) ||
    puertoAplicacion <= 0 ||
    puertoAplicacion > 65535) {
    throw new Error('PORT debe ser un puerto válido');
}

if (!secretoJWT || secretoJWT.length < 32) {
    throw new Error('JWT_SECRETO debe tener al menos 32 caracteres');
}

if (!Number.isInteger(expiracionRefreshDias) ||
    expiracionRefreshDias <= 0) {
    throw new Error('JWT_REFRESH_EXPIRACION_DIAS debe ser un número positivo');
}

export const env = {
    nodeEnv: process.env.NODE_ENV ?? 'development',

    port: puertoAplicacion,

    database: {
        server: process.env.DB_SERVER!,
        port: puertoBaseDatos,
        name: process.env.DB_DATABASE!,
        user: process.env.DB_USER!,
        password: process.env.DB_PASSWORD!,
        encrypt: process.env.DB_ENCRYPT === 'true',
        trustServerCertificate:
            process.env.DB_TRUST_SERVER_CERTIFICATE === 'true'
    },

    seguridad: {
        secretoJWT: secretoJWT!,
        expiracionJWT,
        expiracionRefreshDias
    }
};
    