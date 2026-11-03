import { obtenerCategoriaPorID } from '../repositorio/categoria-detalle.repositorio';

import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';

export const obtenerCategoriaDetalle = async (
  idCategoria: number
) => {
  const categoria = await obtenerCategoriaPorID(idCategoria);

  if (!categoria) {
    throw new ErrorAplicacion(
      'Categoría no encontrada',
      50012,
      404
    );
  }

  return categoria;
};