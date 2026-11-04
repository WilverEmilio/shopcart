import type { Request, Response, NextFunction } from 'express';
import { eliminarCategoriaServicio } from '../servicios/categorias.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';

export const eliminarCategoriaControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idCategoria = Number(req.params.id);

    await eliminarCategoriaServicio(obtenerIdActor(req), idCategoria);

    res.status(200).json({
      mensaje: 'Categoría eliminada correctamente.',
      datos: { idCategoria }
    });
  } catch (error) {
    next(error);
  }
};