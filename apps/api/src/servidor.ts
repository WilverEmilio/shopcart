import aplicacion from './aplicacion';
import { env } from './config/env';
import { cerrarConexion } from './config/base-de-datos';
import { inicializarSemillas } from './semillas/inicializar-semillas';
import { iniciarJobReservas, detenerJobReservas } from './jobs/reservas.job';

const iniciarServidor = async (): Promise<void> => {
    try {
        await inicializarSemillas();

        const servidor = aplicacion.listen(env.port, () => {
            console.log(`Servidor iniciado en el puerto: ${env.port}`);
        });

        iniciarJobReservas();

        let cerrando = false;

        const cerrarServidor = (senal: string): void => {
            if (cerrando) return;
            cerrando = true;
            console.log(`Señal ${senal} recibida; cerrando el servidor...`);

            detenerJobReservas();
            
            setTimeout(() => {
                console.error('Cierre forzado por tiempo de espera.');
                process.exit(1);
            }, 10_000).unref();

            servidor.close(async () => {
                try {
                    await cerrarConexion();
                    console.log('Servidor y conexión a la base de datos cerrados.');
                    process.exit(0);
                } catch (error) {
                    console.error('Error al cerrar la conexión:', error);
                    process.exit(1);
                }
            });
        };

        process.on('SIGINT', () => cerrarServidor('SIGINT'));
        process.on('SIGTERM', () => cerrarServidor('SIGTERM'));
    } catch (error) {
        console.error('Error al inicializar el servidor:', error);
        await cerrarConexion().catch(() => undefined);
        process.exitCode = 1;
    }
};

void iniciarServidor();