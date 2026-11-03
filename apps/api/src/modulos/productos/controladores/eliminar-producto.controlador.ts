import type { Request, Response, NextFunction } from 'express';

import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { eliminarProductoServicio } from '../servicios/productos.servicio';

export const eliminarProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idProducto = Number(req.params.id);
    const idUsuarioActor = req.usuarioAutenticado?.idUsuario;

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

    const resultado = await eliminarProductoServicio(
      idUsuarioActor,
      idProducto
    );

    const fueEliminado = resultado.Resultado === 'ELIMINADO';

    res.status(200).json({
      mensaje: fueEliminado
        ? 'Producto eliminado correctamente.'
        : 'El producto tenía historial asociado y fue desactivado.',
      datos: {
        idProducto: resultado.IDProducto,
        resultado: resultado.Resultado
      }
    });
  } catch (error) {
    next(error);
  }
};