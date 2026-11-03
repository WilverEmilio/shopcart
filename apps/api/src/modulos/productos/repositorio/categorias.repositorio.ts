import sql from 'mssql';

import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';

import type {
  CategoriaBaseDatos,
  FiltrosCategorias,
  ResultadoCategorias
} from '../tipos/categoria.tipo';

export const listarCategorias = async (
  filtros: FiltrosCategorias
): Promise<ResultadoCategorias> => {
  const resultado = await ejecutarProcedimiento<CategoriaBaseDatos>(
    'dbo.SP_Categorias_Listar',
    solicitud => {
      solicitud.input(
        'Busqueda',
        sql.NVarChar(100),
        filtros.busqueda ?? null
      );

      solicitud.input(
        'Activo',
        sql.Bit,
        filtros.activo ?? null
      );

      solicitud.input(
        'OrdenarPor',
        sql.NVarChar(20),
        filtros.ordenarPor
      );

      solicitud.input(
        'Direccion',
        sql.NVarChar(4),
        filtros.direccion
      );

      solicitud.input(
        'Pagina',
        sql.Int,
        filtros.pagina
      );

      solicitud.input(
        'TamanoPagina',
        sql.Int,
        filtros.tamanoPagina
      );
    }
  );

  const categorias = resultado.recordset;

  return {
    categorias,
    totalRegistros: categorias[0]?.TotalRegistros ?? 0,
    pagina: filtros.pagina,
    tamanoPagina: filtros.tamanoPagina
  };
};