import aplicacion from "./aplicacion";
import { env } from "./config/env";

const servidor = aplicacion.listen(env.port, () => {
    console.log(`Servidor iniciado en el puerto: ${env.port}`);
});

const cerrarServidor = () => {
    servidor.close(() =>{
        console.log('Servidor cerrado');
    });
};

process.on('SIGINT', cerrarServidor);
process.on('SIGTERM', cerrarServidor);
