import { crearCategoria } from "../repositorio/categoria-crear.repositorio";

export const crearCategoriaServicio = async (
  idUsuarioActor: number,
  nombre: string,
  descripcion: string | null
): Promise<number> => {
  return await crearCategoria(
    idUsuarioActor,
    nombre,
    descripcion
  );
};