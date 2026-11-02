export interface ProductoDetalleBaseDatos {
  IDProducto: number;
  Nombre: string;
  Descripcion: string | null;
  Activo: boolean;
  IDCategoria: number;
  Categoria: string;
  FechaCreacion: Date;
  FechaActualizacion: Date | null;
}

export interface ImagenProductoBaseDatos {
  IDImagenProducto: number;
  Url: string;
  Orden: number;
  EsPrincipal: boolean;
}

export interface VarianteProductoBaseDatos {
  IDVariante: number;
  SKU: string;
  Precio: number;
  ExistenciaDisponible: number;
  Activo: boolean;
  ExistenciaFisica: number | null;
  ExistenciaReservada: number | null;
}

export interface AtributoVarianteBaseDatos {
  IDVariante: number;
  Atributo: string;
  Valor: string;
}

export interface ProductoDetalle {
  producto: ProductoDetalleBaseDatos;
  imagenes: ImagenProductoBaseDatos[];
  variantes: VarianteProductoBaseDatos[];
  atributos: AtributoVarianteBaseDatos[];
}