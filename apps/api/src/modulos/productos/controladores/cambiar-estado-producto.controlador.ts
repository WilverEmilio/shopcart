import type { Request, Response, NextFunction } from 'express';

import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { cambiarEstadoProductoServicio } from '../servicios/productos.servicio';

export const cambiarEstadoProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idProducto = Number(req.params.id);
    const idUsuarioActor = req.usuarioAutenticado?.idUsuario;
    const { activo } = req.body;

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

    if (typeof activo !== 'boolean') {
      throw new ErrorAplicacion(
        'El campo activo debe ser verdadero o falso.',
        50053,
        400
      );
    }

    const resultado = await cambiarEstadoProductoServicio(
      idUsuarioActor,
      idProducto,
      activo
    );

    res.status(200).json({
      mensaje: resultado.Activo
        ? 'Producto activado correctamente.'
        : 'Producto desactivado correctamente.',
      datos: {
        idProducto: resultado.IDProducto,
        activo: resultado.Activo
      }
    });
  } catch (error) {
    next(error);
  }
};