import aplicacion from './aplicacion';
import { env } from './config/env';
import { inicializarSemillas } from './semillas/inicializar-semillas';

const iniciarServidor = async (): Promise<void> => {
    try {
        await inicializarSemillas();

        const servidor = aplicacion.listen(env.port, () => {
            console.log(`Servidor iniciado en el puerto: ${env.port}`);
        });

        const cerrarServidor = (): void => {
            servidor.close(() => {
                console.log('Servidor cerrado.');
            });
        };

        process.on('SIGINT', cerrarServidor);
        process.on('SIGTERM', cerrarServidor);
    } catch (error) {
        console.error('Error al inicializar el servidor:', error);
        process.exitCode = 1;
    }
};

void iniciarServidor();