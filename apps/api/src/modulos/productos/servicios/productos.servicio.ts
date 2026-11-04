import {
  crearProducto,
  actualizarProducto,
  cambiarEstadoProducto,
  eliminarProducto
} from '../repositorio/productos.repositorio';
import type { DatosCrearProducto } from '../tipos/producto-crear.tipo';
import type { DatosActualizarProducto } from '../tipos/producto-actualizar.tipo';

export const crearProductoServicio = (idUsuarioActor: number, datos: DatosCrearProducto) =>
  crearProducto(idUsuarioActor, datos);

export const actualizarProductoServicio = (
  idUsuarioActor: number, idProducto: number, datos: DatosActualizarProducto
) => actualizarProducto(
  idUsuarioActor, 
  idProducto, 
  datos
);

export const cambiarEstadoProductoServicio = (
  idUsuarioActor: number, idProducto: number, activo: boolean
) => cambiarEstadoProducto(
  idUsuarioActor, 
  idProducto, 
  activo
);

export const eliminarProductoServicio = (idUsuarioActor: number, idProducto: number) =>
  eliminarProducto(idUsuarioActor, 
    idProducto
  );