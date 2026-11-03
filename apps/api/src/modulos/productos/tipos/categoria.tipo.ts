export interface FiltrosCategorias {
  busqueda?: string;
  activo?: boolean;
  ordenarPor: 'Nombre' | 'FechaCreacion';
  direccion: 'ASC' | 'DESC';
  pagina: number;
  tamanoPagina: number;
}

export interface CategoriaBaseDatos {
  IDCategoria: number;
  Nombre: string;
  Descripcion: string | null;
  Activo: boolean;
  FechaCreacion: Date;
  TotalProductos: number;
  TotalRegistros: number;
}

export interface ResultadoCategorias {
  categorias: CategoriaBaseDatos[];
  totalRegistros: number;
  pagina: number;
  tamanoPagina: number;
}