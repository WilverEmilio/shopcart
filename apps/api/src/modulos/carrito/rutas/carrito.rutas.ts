import { Router } from 'express';
import { autenticar, autenticarOpcional } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import {
    agregarItemEsquema, actualizarCantidadEsquema,
    idVarianteParametroEsquema, aplicarCuponEsquema
} from '../esquemas/carrito.esquemas';
import {
    obtenerCarritoControlador, agregarItemControlador, actualizarCantidadControlador,
    eliminarItemControlador, fusionarCarritoControlador, aplicarCuponControlador, quitarCuponControlador
} from '../controladores/carrito.controlador';

const rutasCarrito = Router();

rutasCarrito.get('/', autenticarOpcional, obtenerCarritoControlador);
rutasCarrito.post('/items', autenticarOpcional, validar({ body: agregarItemEsquema }), agregarItemControlador);
rutasCarrito.patch('/items/:idVariante', autenticarOpcional,
    validar({ params: idVarianteParametroEsquema, body: actualizarCantidadEsquema }), actualizarCantidadControlador);
rutasCarrito.delete('/items/:idVariante', autenticarOpcional,
    validar({ params: idVarianteParametroEsquema }), eliminarItemControlador);

rutasCarrito.post('/fusionar', autenticar, autorizarRoles('Cliente'), fusionarCarritoControlador);
rutasCarrito.post('/cupon', autenticar, autorizarRoles('Cliente'), validar({ body: aplicarCuponEsquema }), aplicarCuponControlador);
rutasCarrito.delete('/cupon', autenticar, autorizarRoles('Cliente'), quitarCuponControlador);

export default rutasCarrito;