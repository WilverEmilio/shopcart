import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { idParametroEsquema, cambiarEstadoEsquema } from '../../../shared/esquemas/comunes.esquema';
import { crearCuponEsquema, actualizarCuponEsquema, cuponesQueryEsquema } from '../esquemas/cupon.esquema';
import {
    listarCuponesControlador, obtenerCuponControlador, crearCuponControlador,
    actualizarCuponControlador, cambiarEstadoCuponControlador, eliminarCuponControlador
} from '../controladores/cupones.controlador';

const rutasCupones = Router();
rutasCupones.use(autenticar, autorizarRoles('Administrador'));

rutasCupones.get('/', validar({ query: cuponesQueryEsquema }), listarCuponesControlador);
rutasCupones.get('/:id', validar({ params: idParametroEsquema }), obtenerCuponControlador);
rutasCupones.post('/', validar({ body: crearCuponEsquema }), crearCuponControlador);
rutasCupones.put('/:id', validar({ params: idParametroEsquema, body: actualizarCuponEsquema }), actualizarCuponControlador);
rutasCupones.patch('/:id/estado', validar({ params: idParametroEsquema, body: cambiarEstadoEsquema }), cambiarEstadoCuponControlador);
rutasCupones.delete('/:id', validar({ params: idParametroEsquema }), eliminarCuponControlador);

export default rutasCupones;