import clienteHttp from '../../../servicios/clienteHttp';
import type { Pagina, RespuesaApi } from '../../../tipos/respuestaApi';
import type {
  DatosDevolucion,
  DetallePedido,
  EstadoAvance,
  FiltrosMisPedidos,
  FiltrosPedidosGestion,
  PedidoResumenCliente,
  PedidoResumenGestion,
  ResultadoCancelacion,
  Transicion,
} from '../tipos/pedido';

export async function listarMisPedidos(filtros: FiltrosMisPedidos, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<Pagina<PedidoResumenCliente>>>('/pedidos/mios', {
    params: filtros,
    signal,
  });
  return data.datos;
}

export async function listarPedidosGestion(filtros: FiltrosPedidosGestion, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<Pagina<PedidoResumenGestion>>>('/pedidos', {
    params: filtros,
    signal,
  });
  return data.datos;
}

export async function obtenerDetallePedido(idPedido: number, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<DetallePedido>>(`/pedidos/${idPedido}`, { signal });
  return data.datos;
}

export async function listarTransiciones(signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<Transicion[]>>('/pedidos/transiciones', { signal });
  return data.datos;
}

export async function cancelarPedido(idPedido: number, motivo: string) {
  const { data } = await clienteHttp.post<RespuesaApi<ResultadoCancelacion>>(`/pedidos/${idPedido}/cancelar`, { motivo });
  return data.datos;
}

export async function avanzarEstado(idPedido: number, estado: EstadoAvance, comentario: string | null) {
  const { data } = await clienteHttp.patch<RespuesaApi<{ idPedido: number; estado: string; cambio: boolean }>>(
    `/pedidos/${idPedido}/estado`,
    { estado, comentario }
  );
  return data.datos;
}

export async function registrarDevolucion(idPedido: number, datos: DatosDevolucion) {
  const { data } = await clienteHttp.post<
    RespuesaApi<{ idDevolucion: number; idPedido: number; estadoPedido: string; montoReembolso: number }>
  >(`/pedidos/${idPedido}/devoluciones`, datos);
  return data.datos;
}