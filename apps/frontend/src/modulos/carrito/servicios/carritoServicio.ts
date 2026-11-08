import axios from 'axios';
import clienteHttp from '../../../servicios/clienteHttp';
import { useCarritoEstado } from '../../../estados/carritoEstado';
import type { RespuesaApi } from '../../../tipos/respuestaApi';
import type { Carrito, RespuestaAgregarItem, ResultadoFusion } from '../tipos/carrito';

const cabecerasInvitado = (): Record<string, string> => {
  const token = useCarritoEstado.getState().tokenCarrito;
  return token ? { 'x-carrito-token': token } : {};
};

export async function obtenerCarrito(signal?: AbortSignal): Promise<Carrito> {
  const { data } = await clienteHttp.get<RespuesaApi<Carrito>>('/carrito', {
    headers: cabecerasInvitado(),
    signal,
  });
  return data.datos;
}

export async function agregarItem(idVariante: number, cantidad: number): Promise<Carrito> {
  const { data } = await clienteHttp.post<RespuesaApi<RespuestaAgregarItem>>(
    '/carrito/items',
    { idVariante, cantidad },
    { headers: cabecerasInvitado() }
  );

  const { tokenCarrito, ...carrito } = data.datos;
  if (tokenCarrito) useCarritoEstado.getState().establecerToken(tokenCarrito);
  return carrito;
}

export async function actualizarCantidad(idVariante: number, cantidad: number): Promise<Carrito> {
  const { data } = await clienteHttp.patch<RespuesaApi<Carrito>>(
    `/carrito/items/${idVariante}`,
    { cantidad },
    { headers: cabecerasInvitado() }
  );
  return data.datos;
}

export async function eliminarItem(idVariante: number): Promise<Carrito> {
  const { data } = await clienteHttp.delete<RespuesaApi<Carrito>>(`/carrito/items/${idVariante}`, {
    headers: cabecerasInvitado(),
  });
  return data.datos;
}

export async function aplicarCupon(codigo: string): Promise<Carrito> {
  const { data } = await clienteHttp.post<RespuesaApi<Carrito>>('/carrito/cupon', { codigo });
  return data.datos;
}

export async function quitarCupon(): Promise<Carrito> {
  const { data } = await clienteHttp.delete<RespuesaApi<Carrito>>('/carrito/cupon');
  return data.datos;
}

export async function fusionarCarritoInvitado(tokenAcceso: string): Promise<ResultadoFusion | null> {
  const { tokenCarrito, limpiarToken, establecerAjustes } = useCarritoEstado.getState();
  if (!tokenCarrito) return null;

  try {
    const { data } = await clienteHttp.post<RespuesaApi<ResultadoFusion>>('/carrito/fusionar', undefined, {
      headers: { Authorization: `Bearer ${tokenAcceso}`, 'x-carrito-token': tokenCarrito },
    });
    limpiarToken();
    establecerAjustes(data.datos.ajustes);
    return data.datos;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) limpiarToken();
    return null;
  }
}