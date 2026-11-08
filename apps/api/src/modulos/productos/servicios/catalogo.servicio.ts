import { buscarProductos } from '../repositorio/catalogo.repositorio';
import { mapearFilas } from '../../../shared/utilidades/mapeo';
import type {
  FiltrosCatalogo
} from '../tipos/catalogo.tipo';

export const obtenerCatalogo = async (
  filtros: FiltrosCatalogo,
  idUsuarioActor: number | null
) => {
    const resultado = await buscarProductos(filtros, idUsuarioActor)

    return {
    ...resultado,
    productos: mapearFilas(
      resultado.productos.map(({ TotalRegistros: _total, ...resto }) => resto)
    ),
  };
};