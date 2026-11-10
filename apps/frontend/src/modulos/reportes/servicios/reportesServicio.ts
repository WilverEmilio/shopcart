import clienteHttp from '../../../servicios/clienteHttp';
import type { RespuesaApi } from '../../../tipos/respuestaApi';
import type {
  Agrupacion,
  FilaTopProducto,
  FilaVentasCategoria,
  FilaVentasPeriodo,
  FiltrosAbandonados,
  OrdenTop,
  RangoFechas,
  ResultadoAbandonados,
  ResumenDashboard,
} from '../tipos/reportes';

export async function obtenerResumen(rango: RangoFechas, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<ResumenDashboard>>('/reportes/resumen', { params: rango, signal });
  return data.datos;
}

export async function ventasPorPeriodo(rango: RangoFechas, agrupacion: Agrupacion, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<FilaVentasPeriodo[]>>('/reportes/ventas-periodo', {
    params: { ...rango, agrupacion },
    signal,
  });
  return data.datos;
}

export async function ventasPorCategoria(rango: RangoFechas, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<FilaVentasCategoria[]>>('/reportes/ventas-categoria', {
    params: rango,
    signal,
  });
  return data.datos;
}

export async function topProductos(rango: RangoFechas, ordenarPor: OrdenTop, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<FilaTopProducto[]>>('/reportes/top-productos', {
    params: { ...rango, ordenarPor, top: 10 },
    signal,
  });
  return data.datos.map((f) => ({ ...f, ranking: Number(f.ranking) }));
}

export async function carritosAbandonados(filtros: FiltrosAbandonados, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<ResultadoAbandonados>>('/reportes/carritos-abandonados', {
    params: filtros,
    signal,
  });
  return data.datos;
}