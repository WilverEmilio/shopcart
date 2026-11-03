import sql from 'mssql';

import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import { ResultadoCambiarEstadoCategoriaBaseDatos } from '../tipos/categoria-estado.tipo';
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

export const cambiarEstadoCategoria = async (
    idUsuarioActor: number,
    idCategoria: number,
    activo: boolean
): Promise<ResultadoCambiarEstadoCategoriaBaseDatos> => {
    const resultado = await ejecutarProcedimiento<ResultadoCambiarEstadoCategoriaBaseDatos>(
        'dbo.SP_Categorias_CambiarEstado',
        (solicitud) => {
            solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
            solicitud.input('IDCategoria', sql.Int, idCategoria);
            solicitud.input('Activo', sql.Bit, activo);
        }
    );

    const categoria = resultado.recordset[0];

    if (!categoria) {
        throw new Error('No se pudo confirmar el cambio de estado de la categoría.');
    }

    return categoria;
};