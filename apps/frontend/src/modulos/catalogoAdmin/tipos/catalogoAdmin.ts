export interface CategoriaAdmin {
  idCategoria: number;
  nombre: string;
  descripcion: string | null;
  activo: boolean;
  fechaCreacion: string;
  totalProductos: number;
}

export interface ResultadoCategoriasAdmin {
  categorias: CategoriaAdmin[];
  totalRegistros: number;
  pagina: number;
  tamanoPagina: number;
}

export interface FiltrosCategoriasAdmin {
  busqueda?: string;
  activo?: boolean;
  ordenarPor?: 'Nombre' | 'FechaCreacion';
  direccion?: 'ASC' | 'DESC';
  pagina?: number;
  registrosPorPagina?: number;
}

export interface DatosCategoria {
  nombre: string;
  descripcion: string | null;
}

export interface AtributoCatalogo {
  idAtributo: number;
  nombre: string;
}

export interface AtributoProducto {
  atributo: string;
  valor: string;
}

export interface DatosVariante {
  sku: string;
  precio: number;
  atributos: AtributoProducto[];
}

export interface DatosEdicionVariante {
  sku: string;
  atributos: AtributoProducto[];
}

export interface ImagenProductoPayload {
  url: string;
  orden: number;
  esPrincipal: boolean;
}

export interface DatosProductoNuevo {
  idCategoria: number;
  nombre: string;
  descripcion: string | null;
  variantes: DatosVariante[];
  imagenes: ImagenProductoPayload[];
}

export interface DatosProductoEdicion {
  idCategoria: number;
  nombre: string;
  descripcion: string | null;
}

export type ResultadoEliminacion = 'ELIMINADO' | 'DESACTIVADO';

export interface RespuestaEliminacion {
  resultado: ResultadoEliminacion;
  mensaje: string;
}

export interface AtributoFormulario {
  atributo: string;
  valor: string;
}

export interface VarianteFormulario {
  sku: string;
  precio: string;
  atributos: AtributoFormulario[];
}

export interface ImagenesFormulario {
  urls: string[];
  principal: number;
}