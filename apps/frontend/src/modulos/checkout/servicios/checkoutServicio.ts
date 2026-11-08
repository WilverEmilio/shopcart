import clienteHttp from '../../../servicios/clienteHttp';
import type { RespuesaApi } from '../../../tipos/respuestaApi';
import type { MetodoEnvio, PagoIniciado, PedidoConfirmado } from '../tipos/checkout';

export async function listarMetodosEnvio(signal?: AbortSignal): Promise<MetodoEnvio[]> {
  const { data } = await clienteHttp.get<RespuesaApi<MetodoEnvio[]>>('/checkout/envios', { signal });
  return data.datos;
}

export async function iniciarPago(
  clave: string,
  datos: { idDireccion: number; idMetodoEnvio: number; totalEsperado: number }
): Promise<PagoIniciado> {
  const { data } = await clienteHttp.post<RespuesaApi<PagoIniciado>>('/checkout/pagos', datos, {
    headers: { 'Idempotency-Key': clave },
  });
  return data.datos;
}

export async function confirmarPago(clave: string, tokenPago: string): Promise<PedidoConfirmado> {
  const { data } = await clienteHttp.post<RespuesaApi<PedidoConfirmado>>(
    '/checkout/pagos/confirmar',
    { tokenPago },
    { headers: { 'Idempotency-Key': clave } }
  );
  return data.datos;
}