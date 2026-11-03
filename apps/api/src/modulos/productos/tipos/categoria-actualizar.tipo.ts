export interface DatosActualizarCategoria {
    nombre: string;
    descripcion?: string | null;
}

export interface ResultadoActualizarCategoriaBaseDatos {
    IDCategoria: number;
}