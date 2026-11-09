import clienteHttp from '../../../servicios/clienteHttp';
import type { RespuesaApi } from '../../../tipos/respuestaApi';
import type {
  AtributoCatalogo,
  DatosCategoria,
  DatosEdicionVariante,
  DatosProductoEdicion,
  DatosProductoNuevo,
  DatosVariante,
  FiltrosCategoriasAdmin,
  ImagenProductoPayload,
  RespuestaEliminacion,
  ResultadoCategoriasAdmin,
  ResultadoEliminacion,
  CategoriaAdmin,

} from '../tipos/catalogoAdmin';

type Fila = Record<string, unknown>;

function extraerLista(origen: unknown): Fila[] {
  if (Array.isArray(origen)) return origen as Fila[];
  if (!origen || typeof origen !== 'object') return [];

  const objeto = origen as Fila;
  const claves = Object.keys(objeto);

  if (claves.length > 0 && claves.every((clave) => /^\d+$/.test(clave))) {
    return Object.values(objeto) as Fila[];
  }

  for (const clave of ['categorias', 'items']) {
    const anidada = extraerLista(objeto[clave]);
    if (anidada.length > 0) return anidada;
  }
  return [];
}

function aCategoria(fila: Fila): CategoriaAdmin {
  return {
    idCategoria: Number(fila.idCategoria ?? fila.IDCategoria),
    nombre: String(fila.nombre ?? fila.Nombre ?? ''),
    descripcion: (fila.descripcion ?? fila.Descripcion ?? null) as string | null,
    activo: Boolean(fila.activo ?? fila.Activo),
    fechaCreacion: String(fila.fechaCreacion ?? fila.FechaCreacion ?? ''),
    totalProductos: Number(fila.totalProductos ?? fila.TotalProductos ?? 0),
  };
}

export async function listarCategoriasAdmin(
  filtros: FiltrosCategoriasAdmin,
  signal?: AbortSignal
): Promise<ResultadoCategoriasAdmin> {
  const { data } = await clienteHttp.get<RespuesaApi<unknown>>('/catalogo/categorias', {
    params: filtros,
    signal,
  });

  const filas = extraerLista(data.datos);
  const origen = (data.datos ?? {}) as Fila;

  return {
    categorias: filas.map(aCategoria),
    totalRegistros: Number(origen.totalRegistros ?? filas[0]?.TotalRegistros ?? filas.length),
    pagina: Number(origen.pagina ?? filtros.pagina ?? 1),
    tamanoPagina: Number(origen.tamanoPagina ?? filtros.registrosPorPagina ?? 20),
  };
}

export async function crearCategoria(datos: DatosCategoria) {
  await clienteHttp.post('/catalogo/categorias', datos);
}

export async function actualizarCategoria(idCategoria: number, datos: DatosCategoria) {
  await clienteHttp.put(`/catalogo/categorias/${idCategoria}`, datos);
}

export async function cambiarEstadoCategoria(idCategoria: number, activo: boolean) {
  await clienteHttp.patch(`/catalogo/categorias/${idCategoria}/estado`, { activo });
}

export async function eliminarCategoria(idCategoria: number) {
  await clienteHttp.delete(`/catalogo/categorias/${idCategoria}`);
}

export async function listarAtributos(signal?: AbortSignal): Promise<AtributoCatalogo[]> {
  const { data } = await clienteHttp.get<RespuesaApi<Record<string, unknown>[]>>('/catalogo/atributos', { signal });
  return data.datos.map((a) => ({
    idAtributo: Number(a.idAtributo ?? a.IDAtributo),
    nombre: String(a.nombre ?? a.Nombre),
  }));
}

export async function crearProducto(datos: DatosProductoNuevo): Promise<number> {
  const { data } = await clienteHttp.post<RespuesaApi<{ idProducto: number }>>('/catalogo/productos', datos);
  return data.datos.idProducto;
}

export async function actualizarProducto(idProducto: number, datos: DatosProductoEdicion) {
  await clienteHttp.put(`/catalogo/productos/${idProducto}`, datos);
}

export async function cambiarEstadoProducto(idProducto: number, activo: boolean) {
  await clienteHttp.patch(`/catalogo/productos/${idProducto}/estado`, { activo });
}

export async function eliminarProducto(idProducto: number): Promise<RespuestaEliminacion> {
  const { data } = await clienteHttp.delete<RespuesaApi<{ idProducto: number; resultado: ResultadoEliminacion }>>(
    `/catalogo/productos/${idProducto}`
  );
  return { resultado: data.datos.resultado, mensaje: data.mensaje };
}

export async function reemplazarImagenes(idProducto: number, imagenes: ImagenProductoPayload[]) {
  await clienteHttp.put(`/catalogo/productos/${idProducto}/imagenes`, { imagenes });
}

export async function crearVariante(idProducto: number, datos: DatosVariante) {
  await clienteHttp.post(`/catalogo/productos/${idProducto}/variantes`, datos);
}

export async function actualizarVariante(idVariante: number, datos: DatosEdicionVariante) {
  await clienteHttp.put(`/catalogo/variantes/${idVariante}`, datos);
}

export async function cambiarPrecioVariante(idVariante: number, precio: number) {
  await clienteHttp.patch(`/catalogo/variantes/${idVariante}/precio`, { precio });
}

export async function cambiarEstadoVariante(idVariante: number, activo: boolean) {
  await clienteHttp.patch(`/catalogo/variantes/${idVariante}/estado`, { activo });
}

export async function eliminarVariante(idVariante: number): Promise<RespuestaEliminacion> {
  const { data } = await clienteHttp.delete<RespuesaApi<{ idVariante: number; resultado: ResultadoEliminacion }>>(
    `/catalogo/variantes/${idVariante}`
  );
  return { resultado: data.datos.resultado, mensaje: data.mensaje };
}