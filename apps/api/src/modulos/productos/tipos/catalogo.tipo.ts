export interface FiltrosCatalogo {
  texto?: string;
  idCategoria?: number;
  precioMin?: number;
  precioMax?: number;
  soloDisponibles: boolean;
  activo?: boolean;
  ordenarPor: 'Nombre' | 'Precio' | 'FechaCreacion';
  direccion: 'ASC' | 'DESC';
  pagina: number;
  tamanoPagina: number;
}

export interface ProductoCatalogoBaseDatos {
  IDProducto: number;
  Nombre: string;
  Activo: boolean;
  IDCategoria: number;
  Categoria: string;
  FechaCreacion: Date;
  PrecioDesde: number;
  PrecioHasta: number;
  Disponible: number;
  TotalVariantes: number;
  ImagenPrincipal: string | null;
  TotalRegistros: number;
}

export interface ResultadoCatalogo {
  productos: ProductoCatalogoBaseDatos[];
  totalRegistros: number;
  pagina: number;
  tamanoPagina: number;
}