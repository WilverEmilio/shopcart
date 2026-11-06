import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import {
    rangoQueryEsquema, ventasPeriodoQueryEsquema, topProductosQueryEsquema, abandonadosQueryEsquema
} from '../esquemas/reporte.esquema';
import {
    resumenControlador, ventasPeriodoControlador, ventasCategoriaControlador,
    topProductosControlador, carritosAbandonadosControlador
} from '../controladores/reporte.controlador';

const rutasReportes = Router();
rutasReportes.use(autenticar, autorizarRoles('Administrador'));

rutasReportes.get('/resumen', validar({ query: rangoQueryEsquema }), resumenControlador);
rutasReportes.get('/ventas-periodo', validar({ query: ventasPeriodoQueryEsquema }), ventasPeriodoControlador);
rutasReportes.get('/ventas-categoria', validar({ query: rangoQueryEsquema }), ventasCategoriaControlador);
rutasReportes.get('/top-productos', validar({ query: topProductosQueryEsquema }), topProductosControlador);
rutasReportes.get('/carritos-abandonados', validar({ query: abandonadosQueryEsquema }), carritosAbandonadosControlador);

export default rutasReportes;