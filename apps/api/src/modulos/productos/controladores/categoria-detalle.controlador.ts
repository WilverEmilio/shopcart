import type { Request, Response, NextFunction } from 'express';

import { obtenerCategoriaDetalle } from '../servicios/categoria-detalle.servicio';

export const obtenerCategoriaDetalleControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idCategoria = Number(req.params.id);

    if (!Number.isInteger(idCategoria) || idCategoria <= 0) {
      res.status(400).json({
        mensaje: 'El identificador de la categoría no es válido'
      });
      return;
    }

    const resultado = await obtenerCategoriaDetalle(idCategoria);

    res.status(200).json({
      mensaje: 'Categoría obtenida correctamente',
      datos: resultado
    });
  } catch (error) {
    next(error);
  }
};