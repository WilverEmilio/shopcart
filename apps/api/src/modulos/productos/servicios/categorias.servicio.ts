import { listarCategorias } from "../repositorio/categorias.repositorio";
import type { FiltrosCategorias, ResultadoCategorias } from "../tipos/categoria.tipo";

export  const obtenerCategorias = async(
    filtros: FiltrosCategorias
): Promise<ResultadoCategorias> => {
    return await listarCategorias(filtros);
}