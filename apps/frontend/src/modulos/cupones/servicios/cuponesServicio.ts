import clienteHttp from '../../../servicios/clienteHttp';
import type { Pagina, RespuesaApi } from '../../../tipos/respuestaApi';
import type { Cupon, DatosCupon, DatosCuponNuevo, FiltrosCupones } from '../tipos/cupon';

export async function listarCupones(filtros: FiltrosCupones, signal?: AbortSignal) {
  const { data } = await clienteHttp.get<RespuesaApi<Pagina<Cupon>>>('/cupones', { params: filtros, signal });
  return data.datos;
}

export async function crearCupon(datos: DatosCuponNuevo) {
  await clienteHttp.post('/cupones', datos);
}

export async function actualizarCupon(idCupon: number, datos: DatosCupon) {
  await clienteHttp.put(`/cupones/${idCupon}`, datos);
}

export async function cambiarEstadoCupon(idCupon: number, activo: boolean) {
  await clienteHttp.patch(`/cupones/${idCupon}/estado`, { activo });
}

export async function eliminarCupon(idCupon: number) {
  await clienteHttp.delete(`/cupones/${idCupon}`);
}