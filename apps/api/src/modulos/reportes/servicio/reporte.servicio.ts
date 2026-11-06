import * as repositorio from '../repositorio/reporte.repositorio';
import { mapearFila, mapearFilas, paginasFilas } from '../../../shared/utilidades/mapeo';
import type { RangoQuery, VentasPeriodoQuery, TopProductosQuery, AbandonadosQuery } from '../esquemas/reporte.esquema';

export const obtenerResumenServicio = async (idActor: number, q: RangoQuery) =>
    mapearFila(await repositorio.obtenerResumen(idActor, q));

export const ventasPorPeriodoServicio = async (idActor: number, q: VentasPeriodoQuery) =>
    mapearFilas(await repositorio.ventasPorPeriodo(idActor, q));

export const ventasPorCategoriaServicio = async (idActor: number, q: RangoQuery) =>
    mapearFilas(await repositorio.ventasPorCategoria(idActor, q));

export const topProductosServicio = async (idActor: number, q: TopProductosQuery) =>
    mapearFilas(await repositorio.topProductos(idActor, q));

export const carritosAbandonadosServicio = async (idActor: number, q: AbandonadosQuery) => {
    const filas = await repositorio.carritosAbandonados(idActor, q);
    const pagina = paginasFilas(filas, q.pagina, q.registrosPorPagina);
    return {
        ...pagina,
        valorTotal: Number(filas[0]?.ValorTotal ?? 0),
        items: pagina.items.map(({ valorTotal: _valorTotal, ...resto }) => resto)
    };
};