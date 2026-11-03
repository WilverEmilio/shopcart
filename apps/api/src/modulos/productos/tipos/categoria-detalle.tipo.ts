export interface CategoriaDetalleBaseDatos {
  IDCategoria: number;
  Nombre: string;
  Descripcion: string | null;
  Activo: boolean;
  FechaCreacion: Date;
  FechaActualizacion: Date | null;
}