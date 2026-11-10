import clienteHttp from '../../../servicios/clienteHttp';
import type { Pagina, RespuesaApi } from '../../../tipos/respuestaApi';
import type { FiltrosBitacora, RegistroBitacora } from '../tipos/bitacora';

export async function listarBitacora(filtros: FiltrosBitacora, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<Pagina<RegistroBitacora>>>('/bitacora', {
    params: filtros,
    signal,
  });
  return data.datos;
}