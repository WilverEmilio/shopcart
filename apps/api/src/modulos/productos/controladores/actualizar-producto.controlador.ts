import type { Request, Response, NextFunction } from 'express';

import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { actualizarProductoServicio } from '../servicios/productos.servicio';

export const actualizarProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idProducto = Number(req.params.id);
    const idUsuarioActor = req.usuarioAutenticado?.idUsuario;

    const { idCategoria, nombre, descripcion } = req.body;

    if (!Number.isInteger(idProducto) || idProducto <= 0) {
      throw new ErrorAplicacion(
        'El ID del producto no es válido.',
        50053,
        400
      );
    }

    if (!idUsuarioActor) {
      throw new ErrorAplicacion(
        'No se pudo identificar al usuario autenticado.',
        50016,
        401
      );
    }

    if (!Number.isInteger(idCategoria) || idCategoria <= 0) {
      throw new ErrorAplicacion(
        'La categoría seleccionada no es válida.',
        50053,
        400
      );
    }

    if (typeof nombre !== 'string' || nombre.trim().length === 0) {
      throw new ErrorAplicacion(
        'El nombre del producto es obligatorio.',
        50053,
        400
      );
    }

    if (nombre.trim().length > 150) {
      throw new ErrorAplicacion(
        'El nombre no puede superar los 150 caracteres.',
        50053,
        400
      );
    }

    if (
      descripcion !== undefined &&
      descripcion !== null &&
      typeof descripcion !== 'string'
    ) {
      throw new ErrorAplicacion(
        'La descripción debe ser un texto.',
        50053,
        400
      );
    }

    const resultado = await actualizarProductoServicio(
      idUsuarioActor,
      idProducto,
      {
        idCategoria,
        nombre: nombre.trim(),
        descripcion:
          typeof descripcion === 'string'
            ? descripcion.trim() || null
            : descripcion ?? null
      }
    );

    res.status(200).json({
      mensaje: 'Producto actualizado correctamente.',
      datos: {
        idProducto: resultado.IDProducto
      }
    });
  } catch (error) {
    next(error);
  }
};