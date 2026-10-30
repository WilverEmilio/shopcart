import { getConnection } from "./config/database";

const startServer = async(): Promise<void> => {
    try{
        await getConnection();
        console.log('Se establecio conexión con la base de datos correctamente');
    } catch(error){
        console.log('No se pudo conectar con la base de datos:', error);
        process.exit(1);
    }
}; 

void startServer();