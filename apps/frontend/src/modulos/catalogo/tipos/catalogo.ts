export type OrdenCatalogo = 'Nombre' | 'Precio' | 'FechaCreacion';
export type DireccionOrden = 'ASC' | 'DESC';

export interface FiltrosCatalogo {
  texto?: string;
  idCategoria?: number;
  precioMinimo?: number;
  precioMaximo?: number;
  soloDisponibles?: boolean;
  ordenarPor?: OrdenCatalogo;
  direccion?: DireccionOrden;
  pagina?: number;
  registrosPorPagina?: number;
}

export interface ProductoCatalogo {
  idProducto: number;
  nombre: string;
  activo: boolean;
  idCategoria: number;
  categoria: string;
  fechaCreacion: string;
  precioDesde: number;
  precioHasta: number;
  disponible: number;
  totalVariantes: number;
  imagenPrincipal: string | null;
}

export interface ResultadoCatalogo {
  productos: ProductoCatalogo[];
  totalRegistros: number;
  pagina: number;
  tamanoPagina: number;
}

export interface CategoriaPublica {
  idCategoria: number;
  nombre: string;
  descripcion: string | null;
}

export interface CabeceraProducto {
  idProducto: number;
  nombre: string;
  descripcion: string | null;
  activo: boolean;
  idCategoria: number;
  categoria: string;
  fechaCreacion: string;
  fechaActualizacion: string | null;
}

export interface ImagenProducto {
  idImagenProducto: number;
  url: string;
  orden: number;
  esPrincipal: boolean;
}

export interface VarianteProducto {
  idVariante: number;
  sku: string;
  precio: number;
  existenciaDisponible: number;
  activo: boolean;
  existenciaFisica: number | null;
  existenciaReservada: number | null;
}

export interface AtributoVariante {
  idVariante: number;
  atributo: string;
  valor: string;
}

export interface ProductoDetalle {
  producto: CabeceraProducto;
  imagenes: ImagenProducto[];
  variantes: VarianteProducto[];
  atributos: AtributoVariante[];
}