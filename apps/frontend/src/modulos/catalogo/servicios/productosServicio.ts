import clienteHttp from "../../../servicios/clienteHttp";
import type { RespuesaApi } from "../../../tipos/respuestaApi";
import type {
  CategoriaPublica,
  FiltrosCatalogo,
  ProductoDetalle,
  ResultadoCatalogo
} from '../tipos/catalogo';

export async function listarProductos(
  filtros: FiltrosCatalogo,
  signal?: AbortSignal
): Promise<ResultadoCatalogo> {
  const {data} = await clienteHttp.get<RespuesaApi<ResultadoCatalogo>>('/catalogo/productos',{
    params : {
      ...filtros,
      soloDisponible: filtros.soloDisponibles ? true : undefined
    },
    signal,
  });
  return data.datos
}

export async function listarCategoriasPublicas(
  signal?: AbortSignal
):Promise <CategoriaPublica[]>{
  const {data} = await clienteHttp.get<RespuesaApi<CategoriaPublica[]>>('/catalogo/categorias-activas', {signal})
  return data.datos
}

export async function obtenerDetalleProducto(
  idProducto: number,
  signal?: AbortSignal
): Promise<ProductoDetalle> {
  const {data} = await clienteHttp.get<RespuesaApi<ProductoDetalle>>(`/catalogo/productos/${idProducto}`,{
    signal
  });
  return data.datos;
}