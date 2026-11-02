import { buscarProductos } from '../repositorio/catalogo.repositorio';

import type {
  FiltrosCatalogo
} from '../tipos/catalogo.tipo';

export const obtenerCatalogo = async (
  filtros: FiltrosCatalogo,
  idUsuarioActor: number | null
) => {
  return buscarProductos(filtros, idUsuarioActor);
};