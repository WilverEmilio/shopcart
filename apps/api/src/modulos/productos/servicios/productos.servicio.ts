import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { crearProducto } from '../repositorio/productos.repositorio';
import { DatosCrearProducto } from '../tipos/producto-crear.tipo';
import { actualizarProducto } from '../repositorio/productos.repositorio';
import { DatosActualizarProducto } from '../tipos/producto-actualizar.tipo';
import { cambiarEstadoProducto } from '../repositorio/productos.repositorio';
import { ResultadoCambiarEstadoProductoBaseDatos } from '../tipos/producto-estado.tipo';
import { eliminarProducto } from '../repositorio/productos.repositorio';
import type { ResultadoEliminarProductoBaseDatos } from '../tipos/producto-eliminar.tipo';

export const crearProductoServicio = async (
  idUsuarioActor: number,
  datos: DatosCrearProducto
) => {
  if (!Number.isInteger(idUsuarioActor) || idUsuarioActor <= 0) {
    throw new ErrorAplicacion(
      'El usuario que realiza la operación no es válido.',
      50053,
      400
    );
  }

  if (!Number.isInteger(datos.idCategoria) || datos.idCategoria <= 0) {
    throw new ErrorAplicacion(
      'La categoría seleccionada no es válida.',
      50053,
      400
    );
  }

  if (!datos.nombre || !datos.nombre.trim()) {
    throw new ErrorAplicacion(
      'El nombre del producto es obligatorio.',
      50053,
      400
    );
  }

  if (datos.nombre.trim().length > 150) {
    throw new ErrorAplicacion(
      'El nombre del producto no puede superar los 150 caracteres.',
      50053,
      400
    );
  }

  if (!Array.isArray(datos.variantes) || datos.variantes.length === 0) {
    throw new ErrorAplicacion(
      'El producto debe tener al menos una variante.',
      50052,
      400
    );
  }

  if (datos.imagenes !== undefined && !Array.isArray(datos.imagenes)) {
    throw new ErrorAplicacion(
      'El formato de las imágenes no es válido.',
      50053,
      400
    );
  }

  return crearProducto(idUsuarioActor, {
    ...datos,
    nombre: datos.nombre.trim(),
    descripcion: datos.descripcion?.trim() || null,
  });
};

export const actualizarProductoServicio = async (
  idUsuarioActor: number,
  idProducto: number,
  datos: DatosActualizarProducto
) => {
  if (!Number.isInteger(idUsuarioActor) || idUsuarioActor <= 0) {
    throw new ErrorAplicacion(
      'El usuario que realiza la operación no es válido.',
      50053,
      400
    );
  }

  if (!Number.isInteger(idProducto) || idProducto <= 0) {
    throw new ErrorAplicacion(
      'El ID del producto no es válido.',
      50053,
      400
    );
  }

  if (!Number.isInteger(datos.idCategoria) || datos.idCategoria <= 0) {
    throw new ErrorAplicacion(
      'La categoría seleccionada no es válida.',
      50053,
      400
    );
  }

  if (!datos.nombre || !datos.nombre.trim()) {
    throw new ErrorAplicacion(
      'El nombre del producto es obligatorio.',
      50053,
      400
    );
  }

  if (datos.nombre.trim().length > 150) {
    throw new ErrorAplicacion(
      'El nombre no puede superar los 150 caracteres.',
      50053,
      400
    );
  }

  return actualizarProducto(idUsuarioActor, idProducto, {
    ...datos,
    nombre: datos.nombre.trim(),
    descripcion: datos.descripcion?.trim() || null
  });
};

export const cambiarEstadoProductoServicio = async (
  idUsuarioActor: number,
  idProducto: number,
  activo: boolean
): Promise<ResultadoCambiarEstadoProductoBaseDatos> => {
  if (!Number.isInteger(idUsuarioActor) || idUsuarioActor <= 0) {
    throw new ErrorAplicacion(
      'El usuario que realiza la operación no es válido.',
      50053,
      400
    );
  }

  if (!Number.isInteger(idProducto) || idProducto <= 0) {
    throw new ErrorAplicacion(
      'El ID del producto no es válido.',
      50053,
      400
    );
  }

  if (typeof activo !== 'boolean') {
    throw new ErrorAplicacion(
      'El estado del producto debe ser verdadero o falso.',
      50053,
      400
    );
  }

  return cambiarEstadoProducto(idUsuarioActor, idProducto, activo);
};

export const eliminarProductoServicio = async (
  idUsuarioActor: number,
  idProducto: number
): Promise<ResultadoEliminarProductoBaseDatos> => {
  if (!Number.isInteger(idUsuarioActor) || idUsuarioActor <= 0) {
    throw new ErrorAplicacion(
      'El usuario que realiza la operación no es válido.',
      50053,
      400
    );
  }

  if (!Number.isInteger(idProducto) || idProducto <= 0) {
    throw new ErrorAplicacion(
      'El ID del producto no es válido.',
      50053,
      400
    );
  }

  return eliminarProducto(idUsuarioActor, idProducto);
};