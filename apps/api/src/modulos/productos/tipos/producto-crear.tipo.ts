export interface AtributoVariante {
  atributo: string;
  valor: string;
}

export interface VarianteCrear {
  sku: string;
  precio: number;
  atributos?: AtributoVariante[];
}

export interface ImagenProductoCrear {
  url: string;
  orden?: number;
  esPrincipal?: boolean;
}

export interface DatosCrearProducto {
  idCategoria: number;
  nombre: string;
  descripcion?: string | null;
  variantes: VarianteCrear[];
  imagenes?: ImagenProductoCrear[];
}

export interface ResultadoCrearProductoBaseDatos {
  IDProducto: number;
}