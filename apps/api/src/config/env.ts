import  dotenv from 'dotenv'

dotenv.config()

const dbPort = Number(process.env.DB_PORT ?? 1433);
const appPort = Number(process.env.PORT ?? 3000);
const requiredEnvVariables = [
    'DB_SERVER',
    'DB_DATABASE', 
    'DB_USER', 
    'DB_PASSWORD'
];

for (const variable of requiredEnvVariables) {
    if(!process.env[variable]){
        throw new Error(
            `Falta una variable de entorno obligatoria: ${variable}`
        );
    }
}

if (!Number.isInteger(dbPort) || dbPort <= 0 || dbPort > 65535) {
    throw new Error('DB_PORT must be a valid port');
}

if (!Number.isInteger(appPort) || appPort <= 0 || appPort > 65535) {
    throw new Error('PORT must be a valid port');
}

export const env = {
    nodeEnv: process.env.NODE_ENV ?? 'development', 

    port: appPort,

    database: {
        server: process.env.DB_SERVER!,
        port: dbPort,
        name: process.env.DB_DATABASE!, 
        user: process.env.DB_USER!,
        password: process.env.DB_PASSWORD!, 
        encrypt: process.env.DB_ENCRYPT === 'true',
        trustServerCertificate:
            process.env.DB_TRUST_SERVER_CERTIFICATE === 'true'
    }
};