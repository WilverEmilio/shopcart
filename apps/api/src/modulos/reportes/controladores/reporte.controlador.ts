import * as servicio from '../servicio/reporte.servicio';
import { manejar } from '../../../shared/utilidades/controlador';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { RangoQuery, VentasPeriodoQuery, TopProductosQuery, AbandonadosQuery } from '../esquemas/reporte.esquema';

export const resumenControlador = manejar(200, 'Resumen obtenido correctamente',
    req => servicio.obtenerResumenServicio(obtenerIdActor(req), req.query as unknown as RangoQuery));

export const ventasPeriodoControlador = manejar(200, 'Ventas por periodo obtenidas correctamente',
    req => servicio.ventasPorPeriodoServicio(obtenerIdActor(req), req.query as unknown as VentasPeriodoQuery));

export const ventasCategoriaControlador = manejar(200, 'Ventas por categoría obtenidas correctamente',
    req => servicio.ventasPorCategoriaServicio(obtenerIdActor(req), req.query as unknown as RangoQuery));

export const topProductosControlador = manejar(200, 'Productos más vendidos obtenidos correctamente',
    req => servicio.topProductosServicio(obtenerIdActor(req), req.query as unknown as TopProductosQuery));

export const carritosAbandonadosControlador = manejar(200, 'Carritos abandonados obtenidos correctamente',
    req => servicio.carritosAbandonadosServicio(obtenerIdActor(req), req.query as unknown as AbandonadosQuery));