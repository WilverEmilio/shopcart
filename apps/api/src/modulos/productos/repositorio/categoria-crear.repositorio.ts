import sql from 'mssql';

import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';

import type {
  ResultadoCrearCategoriaBaseDatos
} from '../tipos/categoria-crear.tipo';

export const crearCategoria = async (
  idUsuarioActor: number,
  nombre: string,
  descripcion: string | null
): Promise<number> => {
  const resultado = await ejecutarProcedimiento<ResultadoCrearCategoriaBaseDatos>(
    'dbo.SP_Categorias_Crear',
    solicitud => {
      solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
      solicitud.input('Nombre', sql.NVarChar(100), nombre);
      solicitud.input('Descripcion', sql.NVarChar(255), descripcion);
    }
  );

  const idCategoria = resultado.recordset[0]?.IDCategoria;

  if (!idCategoria) {
    throw new Error('No se pudo obtener el ID de la categoría creada');
  }

  return idCategoria;
};