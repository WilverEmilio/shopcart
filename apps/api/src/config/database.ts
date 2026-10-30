import sql from 'mssql'
import {env} from './env'
import { error } from 'node:console';

const databaseConfig: sql.config = {
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

let poolPromise: Promise<sql.ConnectionPool> | null = null;

export const getConnection = async (): Promise<sql.ConnectionPool> => {
    if (!poolPromise){
        const pool = new sql.ConnectionPool(databaseConfig);

        poolPromise = pool.connect().catch((error:unknown) => {
            poolPromise = null; 
            throw error;
        });
    }

    return poolPromise
}

export const closeConnection = async(): Promise<void> => {
    if(poolPromise) {
        const pool = await poolPromise;
        await pool.close();
        poolPromise = null;
    }
};