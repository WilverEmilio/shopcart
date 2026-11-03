export interface DatosActualizarProducto {
  idCategoria: number;
  nombre: string;
  descripcion?: string | null;
}

export interface ResultadoActualizarProductoBaseDatos {
  IDProducto: number;
}