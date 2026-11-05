import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { iniciarPagoEsquema, confirmarPagoEsquema } from '../esquemas/checkout.esquema';
import { listarEnviosControlador, iniciarPagoControlador, confirmarPagoControlador } from '../controladores/checkout.controlador';

const rutasCheckout = Router();

rutasCheckout.get('/envios', listarEnviosControlador);
rutasCheckout.post('/pagos', autenticar, autorizarRoles('Cliente'), validar({ body: iniciarPagoEsquema }), iniciarPagoControlador);
rutasCheckout.post('/pagos/confirmar', autenticar, autorizarRoles('Cliente'), validar({ body: confirmarPagoEsquema }), confirmarPagoControlador);

export default rutasCheckout;