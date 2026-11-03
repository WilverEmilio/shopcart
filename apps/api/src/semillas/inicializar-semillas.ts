import { crearAdministradorSemilla } from './administrador.semilla';

export const inicializarSemillas = async (): Promise<void> => {
    console.log('Inicializando datos semilla...');

    await crearAdministradorSemilla();

    console.log('Inicialización de semillas completada.');
};