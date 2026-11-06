import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import {
    existenciasQueryEsquema, kardexQueryEsquema, conciliacionQueryEsquema, entradaEsquema, ajusteEsquema
} from '../esquemas/inventario.esquema';
import {
    listarExistenciasControlador, listarKardexControlador, obtenerConciliacionControlador,
    registrarEntradaControlador, registrarAjusteControlador
} from '../controladores/inventario.controlador';

const rutasInventario = Router();
rutasInventario.use(autenticar, autorizarRoles('Operador', 'Administrador'));

rutasInventario.get('/existencias', validar({ query: existenciasQueryEsquema }), listarExistenciasControlador);
rutasInventario.get('/kardex', validar({ query: kardexQueryEsquema }), listarKardexControlador);
rutasInventario.get('/conciliacion', validar({ query: conciliacionQueryEsquema }), obtenerConciliacionControlador);
rutasInventario.post('/entradas', validar({ body: entradaEsquema }), registrarEntradaControlador);
rutasInventario.post('/ajustes', validar({ body: ajusteEsquema }), registrarAjusteControlador);

export default rutasInventario;