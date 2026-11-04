import type { Request, Response, NextFunction } from 'express';
import { cambiarEstadoProductoServicio } from '../servicios/productos.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';

export const cambiarEstadoProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const resultado = await cambiarEstadoProductoServicio(
      obtenerIdActor(req),
      Number(req.params.id),
      req.body.activo as boolean
    );

    res.status(200).json({
      mensaje: resultado.Activo
        ? 'Producto activado correctamente.'
        : 'Producto desactivado correctamente.',
      datos: { idProducto: resultado.IDProducto, activo: resultado.Activo }
    });
  } catch (error) {
    next(error);
  }
};