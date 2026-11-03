import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import {
  DatosCrearProducto,
  ResultadoCrearProductoBaseDatos,
} from '../tipos/producto-crear.tipo';
import { DatosActualizarProducto, ResultadoActualizarProductoBaseDatos } from '../tipos/producto-actualizar.tipo';
import type { ResultadoCambiarEstadoProductoBaseDatos } from '../tipos/producto-estado.tipo';
import type { ResultadoEliminarProductoBaseDatos } from '../tipos/producto-eliminar.tipo';

export const crearProducto = async (
  idUsuarioActor: number,
  datos: DatosCrearProducto
): Promise<ResultadoCrearProductoBaseDatos> => {
  const resultado = await ejecutarProcedimiento<ResultadoCrearProductoBaseDatos>(
    'dbo.SP_Productos_Crear',
    (solicitud) => {
      solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
      solicitud.input('IDCategoria', sql.Int, datos.idCategoria);
      solicitud.input('Nombre', sql.NVarChar(150), datos.nombre);
      solicitud.input(
        'Descripcion',
        sql.NVarChar(sql.MAX),
        datos.descripcion ?? null
      );
      solicitud.input(
        'Variantes',
        sql.NVarChar(sql.MAX),
        JSON.stringify(datos.variantes)
      );
      solicitud.input(
        'Imagenes',
        sql.NVarChar(sql.MAX),
        datos.imagenes ? JSON.stringify(datos.imagenes) : null
      );
    }
  );

  const producto = resultado.recordset[0];

  if (!producto) {
    throw new Error('No se pudo crear el producto.');
  }

  return producto;
};

export const actualizarProducto = async (
  idUsuarioActor: number,
  idProducto: number,
  datos: DatosActualizarProducto
): Promise<ResultadoActualizarProductoBaseDatos> => {
  const resultado = await ejecutarProcedimiento<ResultadoActualizarProductoBaseDatos>(
    'dbo.SP_Productos_Actualizar',
    (solicitud) => {
      solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
      solicitud.input('IDProducto', sql.Int, idProducto);
      solicitud.input('IDCategoria', sql.Int, datos.idCategoria);
      solicitud.input('Nombre', sql.NVarChar(150), datos.nombre);
      solicitud.input(
        'Descripcion',
        sql.NVarChar(sql.MAX),
        datos.descripcion ?? null
      );
    }
  );

  const producto = resultado.recordset[0];

  if (!producto) {
    throw new Error('No se pudo actualizar el producto.');
  }

  return producto;
};

export const cambiarEstadoProducto = async (
  idUsuarioActor: number,
  idProducto: number,
  activo: boolean
): Promise<ResultadoCambiarEstadoProductoBaseDatos> => {
  const resultado = await ejecutarProcedimiento<ResultadoCambiarEstadoProductoBaseDatos>(
    'dbo.SP_Productos_CambiarEstado',
    (solicitud) => {
      solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
      solicitud.input('IDProducto', sql.Int, idProducto);
      solicitud.input('Activo', sql.Bit, activo);
    }
  );

  const producto = resultado.recordset[0];

  if (!producto) {
    throw new Error('No se pudo cambiar el estado del producto.');
  }

  return producto;
};

export const eliminarProducto = async (
  idUsuarioActor: number,
  idProducto: number
): Promise<ResultadoEliminarProductoBaseDatos> => {
  const resultado = await ejecutarProcedimiento<ResultadoEliminarProductoBaseDatos>(
    'dbo.SP_Productos_Eliminar',
    (solicitud) => {
      solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
      solicitud.input('IDProducto', sql.Int, idProducto);
    }
  );

  const producto = resultado.recordset[0];

  if (!producto) {
    throw new Error('No se pudo eliminar el producto.');
  }

  return producto;
};