import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { idParametroEsquema } from '../../../shared/esquemas/comunes.esquema';
import { misPedidosQueryEsquema, cancelarPedidoEsquema } from '../esquemas/pedido.esquema';
import {
    listarMisPedidosControlador, obtenerDetallePedidoControlador, cancelarPedidoControlador
} from '../controladores/pedidos.controlador';

const rutasPedidos = Router();
rutasPedidos.use(autenticar);

rutasPedidos.get('/mios', autorizarRoles('Cliente'), validar({ query: misPedidosQueryEsquema }), listarMisPedidosControlador);
rutasPedidos.get('/:id', validar({ params: idParametroEsquema }), obtenerDetallePedidoControlador);
rutasPedidos.post('/:id/cancelar', validar({ params: idParametroEsquema, body: cancelarPedidoEsquema }), cancelarPedidoControlador);

export default rutasPedidos;