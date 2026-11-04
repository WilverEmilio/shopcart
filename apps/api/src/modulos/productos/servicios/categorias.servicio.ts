import { listarCategorias } from "../repositorio/categorias.repositorio";
import type { FiltrosCategorias, ResultadoCategorias } from "../tipos/categoria.tipo";
import { actualizarCategoria } from "../repositorio/catalogo.repositorio";
import { DatosActualizarCategoria } from "../tipos/categoria-actualizar.tipo";
import { cambiarEstadoCategoria } from "../repositorio/categorias.repositorio";
import { ResultadoCambiarEstadoCategoriaBaseDatos } from "../tipos/categoria-estado.tipo";
import { eliminarCategoria } from "../repositorio/categorias.repositorio";

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

export const cambiarEstadoCategoriaServicio = async (
    idUsuarioActor: number,
    idCategoria: number,
    activo: boolean
): Promise<ResultadoCambiarEstadoCategoriaBaseDatos> => {
    return await cambiarEstadoCategoria(
        idUsuarioActor,
        idCategoria,
        activo
    );
};

export const eliminarCategoriaServicio = async (
  idUsuarioActor: number,
  idCategoria: number
): Promise<void> => {
  await eliminarCategoria(idUsuarioActor, idCategoria);
};

export const obtenerCategoriasPublicas = async () => {
    const resultado = await listarCategorias({
        activo: true,
        ordenarPor: 'Nombre',
        direccion: 'ASC',
        pagina: 1,
        tamanoPagina: 100
    });

    // Solo lo que necesita la tienda: sin conteos internos ni fechas
    return resultado.categorias.map(c => ({
        idCategoria: c.IDCategoria,
        nombre: c.Nombre,
        descripcion: c.Descripcion
    }));
};