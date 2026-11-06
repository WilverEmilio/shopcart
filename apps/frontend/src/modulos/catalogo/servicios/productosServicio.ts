import clienteHttp from "../../../servicios/clienteHttp";
import type {
    FiltrosCatalogo,
    RespuestaCatalogo
} from '../tipos/catalogo'

export async function obtenerProductos<T = unknown>(
  filtros: FiltrosCatalogo = {}
): Promise<RespuestaCatalogo<T>> {
  const respuesta = await clienteHttp.get<RespuestaCatalogo<T>>(
    "/catalogo/productos",
    {
      params: filtros,
    }
  );

  return respuesta.data;
}