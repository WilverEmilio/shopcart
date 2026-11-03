import { listarCategorias } from "../repositorio/categorias.repositorio";
import type { FiltrosCategorias, ResultadoCategorias } from "../tipos/categoria.tipo";
import { actualizarCategoria } from "../repositorio/catalogo.repositorio";
import { DatosActualizarCategoria } from "../tipos/categoria-actualizar.tipo";

export  const obtenerCategorias = async(
    filtros: FiltrosCategorias
): Promise<ResultadoCategorias> => {
    return await listarCategorias(filtros);
}

export const actualizarCategoriaServicio = async (
    idUsuarioActor: number,
    idCategoria: number,
    datos: DatosActualizarCategoria
): Promise<number> => {
    return await actualizarCategoria(
        idUsuarioActor,
        idCategoria,
        datos
    );
};