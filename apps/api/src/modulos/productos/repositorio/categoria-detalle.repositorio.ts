import sql from 'mssql';

import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';

import type {
  CategoriaDetalleBaseDatos
} from '../tipos/categoria-detalle.tipo';

export const obtenerCategoriaPorID = async (
  idCategoria: number
): Promise<CategoriaDetalleBaseDatos | null> => {
  const resultado = await ejecutarProcedimiento<CategoriaDetalleBaseDatos>(
    'dbo.SP_Categorias_ObtenerPorID',
    solicitud => {
      solicitud.input('IDCategoria', sql.Int, idCategoria);
    }
  );

  return resultado.recordset[0] ?? null;
};