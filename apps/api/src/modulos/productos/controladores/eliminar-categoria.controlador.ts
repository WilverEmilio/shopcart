import { Request, Response, NextFunction } from 'express';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { eliminarCategoriaServicio } from '../servicios/categorias.servicio';

export const eliminarCategoriaControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idCategoria = Number(req.params.id);
    const idUsuarioActor = req.usuarioAutenticado?.idUsuario;

    if (!Number.isInteger(idCategoria) || idCategoria <= 0) {
      throw new ErrorAplicacion(
        'El identificador de la categoría no es válido.',
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

    await eliminarCategoriaServicio(idUsuarioActor, idCategoria);

    res.status(200).json({
      mensaje: 'Categoría eliminada correctamente.',
      datos: {
        idCategoria
      }
    });
  } catch (error) {
    next(error);
  }
};