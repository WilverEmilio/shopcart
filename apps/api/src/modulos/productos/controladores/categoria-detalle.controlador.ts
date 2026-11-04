import type { Request, Response, NextFunction } from 'express';
import { obtenerCategoriaDetalle } from '../servicios/categoria-detalle.servicio';

export const obtenerCategoriaDetalleControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const resultado = await obtenerCategoriaDetalle(Number(req.params.id));

    res.status(200).json({
      mensaje: 'Categoría obtenida correctamente',
      datos: resultado
    });
  } catch (error) {
    next(error);
  }
};