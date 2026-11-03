import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type {
  FiltrosCatalogo,
  ProductoCatalogoBaseDatos,
  ResultadoCatalogo
} from '../tipos/catalogo.tipo';
import { DatosActualizarCategoria,ResultadoActualizarCategoriaBaseDatos } from '../tipos/categoria-actualizar.tipo';

export const buscarProductos = async (
  filtros: FiltrosCatalogo,
  idUsuarioActor: number | null
): Promise<ResultadoCatalogo> => {

  const resultado = await ejecutarProcedimiento<ProductoCatalogoBaseDatos>(
    'dbo.SP_Catalogo_Buscar',
    (solicitud) => {
      solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
      solicitud.input('Texto', sql.NVarChar(100), filtros.texto ?? null);
      solicitud.input('IDCategoria', sql.Int, filtros.idCategoria ?? null);
      solicitud.input('PrecioMin', sql.Decimal(12, 2), filtros.precioMin ?? null);
      solicitud.input('PrecioMax', sql.Decimal(12, 2), filtros.precioMax ?? null);
      solicitud.input('SoloDisponibles', sql.Bit, filtros.soloDisponibles);
      solicitud.input('Activo', sql.Bit, filtros.activo ?? null);
      solicitud.input('OrdenarPor', sql.NVarChar(20), filtros.ordenarPor);
      solicitud.input('Direccion', sql.NVarChar(4), filtros.direccion);
      solicitud.input('Pagina', sql.Int, filtros.pagina);
      solicitud.input('TamanoPagina', sql.Int, filtros.tamanoPagina);
    }
  );

  const productos = resultado.recordset;
  const totalRegistros = productos.length > 0
    ? productos[0].TotalRegistros
    : 0;

  return {
    productos,
    totalRegistros,
    pagina: filtros.pagina,
    tamanoPagina: filtros.tamanoPagina
  };
};

export const actualizarCategoria = async (
    idUsuarioActor: number,
    idCategoria: number,
    datos: DatosActualizarCategoria
): Promise<number> => {
    const resultado = await ejecutarProcedimiento<ResultadoActualizarCategoriaBaseDatos>(
        'dbo.SP_Categorias_Actualizar',
        (solicitud) => {
            solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
            solicitud.input('IDCategoria', sql.Int, idCategoria);
            solicitud.input('Nombre', sql.NVarChar(100), datos.nombre);
            solicitud.input(
                'Descripcion',
                sql.NVarChar(255),
                datos.descripcion ?? null
            );
        }
    );

    const categoria = resultado.recordset[0];

    if (!categoria) {
        throw new Error('No se pudo confirmar la actualización de la categoría.');
    }

    return categoria.IDCategoria;
};