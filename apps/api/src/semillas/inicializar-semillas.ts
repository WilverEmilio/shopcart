import { crearAdministradorSemilla } from './administrador.semilla';
import { crearUsuariosPrueba } from './usuarios-prueba.semilla';

export const inicializarSemillas = async (): Promise<void> => {
    console.log('Inicializando datos semilla...');

    const idAdministrador = await crearAdministradorSemilla();
    await crearUsuariosPrueba(idAdministrador);
    
    console.log('Inicialización de semillas completada.');
};