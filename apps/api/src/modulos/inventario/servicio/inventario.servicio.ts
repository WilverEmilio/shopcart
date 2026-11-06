import * as repositorio from '../repositorio/inventario.repositorio';
import { paginasFilas } from '../../../shared/utilidades/mapeo';
import type { ExistenciasQuery, KardexQuery, ConciliacionQuery } from '../esquemas/inventario.esquema';

const mapearMovimiento = (r: { IDMovimiento: number; ExistenciaAnterior: number; ExistenciaNueva: number }) => ({
    idMovimiento: r.IDMovimiento, existenciaAnterior: r.ExistenciaAnterior, existenciaNueva: r.ExistenciaNueva
});

export const listarExistenciasServicio = async (idActor: number, q: ExistenciasQuery) =>
    paginasFilas(await repositorio.listarExistencias(idActor, q), q.pagina, q.registrosPorPagina);

export const listarKardexServicio = async (idActor: number, q: KardexQuery) =>
    paginasFilas(await repositorio.listarKardex(idActor, q), q.pagina, q.registrosPorPagina);

export const obtenerConciliacionServicio = async (idActor: number, q: ConciliacionQuery) =>
    paginasFilas(await repositorio.obtenerConciliacion(idActor, q), q.pagina, q.registrosPorPagina);

export const registrarEntradaServicio = async (idActor: number, d: { idVariante: number; cantidad: number; motivo: string }) =>
    mapearMovimiento(await repositorio.registrarEntrada(idActor, d.idVariante, d.cantidad, d.motivo));

export const registrarAjusteServicio = async (idActor: number, d: { idVariante: number; cantidad: number; motivo: string }) =>
    mapearMovimiento(await repositorio.registrarAjuste(idActor, d.idVariante, d.cantidad, d.motivo));