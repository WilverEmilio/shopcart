import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { idParametroEsquema } from '../../../shared/esquemas/comunes.esquema';
import { misPedidosQueryEsquema, cancelarPedidoEsquema, listarPedidosQueryEsquema, devolucionEsquema, avanzarEstadoEsquema } from '../esquemas/pedido.esquema';
import {
    listarMisPedidosControlador, obtenerDetallePedidoControlador, cancelarPedidoControlador,
    listarPedidosControlador, avanzarEstadoControlador, registrarDevolucionControlador,
    listarTransicionesControlador
} from '../controladores/pedidos.controlador';

const rutasPedidos = Router();
const gestores = autorizarRoles('Operador', 'Administrador')
rutasPedidos.use(autenticar);

rutasPedidos.get('/mios', autorizarRoles('Cliente'), validar({ query: misPedidosQueryEsquema }), listarMisPedidosControlador);
rutasPedidos.get('/transiciones', gestores, listarTransicionesControlador)
rutasPedidos.get('/',gestores, validar({query: listarPedidosQueryEsquema}), listarPedidosControlador)

rutasPedidos.get('/:id', validar({ params: idParametroEsquema }), obtenerDetallePedidoControlador);
rutasPedidos.patch('/:id/estado', gestores, validar({ params: idParametroEsquema, body: avanzarEstadoEsquema }), avanzarEstadoControlador);
rutasPedidos.post('/:id/devoluciones', gestores, validar({ params: idParametroEsquema, body: devolucionEsquema }), registrarDevolucionControlador);
rutasPedidos.post('/:id/cancelar', validar({ params: idParametroEsquema, body: cancelarPedidoEsquema }), cancelarPedidoControlador);



export default rutasPedidos;