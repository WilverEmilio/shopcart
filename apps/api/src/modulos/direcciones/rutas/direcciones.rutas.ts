import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { idParametroEsquema } from '../../../shared/esquemas/comunes.esquema';
import { direccionEsquema } from '../esquemas/direccion.esquema';
import {
    listarDireccionesControlador, crearDireccionControlador,
    actualizarDireccionControlador, eliminarDireccionControlador
} from '../controladores/direcciones.controlador';

const rutasDirecciones = Router();
rutasDirecciones.use(autenticar, autorizarRoles('Cliente'));

rutasDirecciones.get('/', listarDireccionesControlador);
rutasDirecciones.post('/', validar({ body: direccionEsquema }), crearDireccionControlador);
rutasDirecciones.put('/:id', validar({ params: idParametroEsquema, body: direccionEsquema }), actualizarDireccionControlador);
rutasDirecciones.delete('/:id', validar({ params: idParametroEsquema }), eliminarDireccionControlador);

export default rutasDirecciones;