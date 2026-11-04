import type { Request, Response, NextFunction } from 'express';
import { eliminarProductoServicio } from '../servicios/productos.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';

export const eliminarProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const resultado = await eliminarProductoServicio(
      obtenerIdActor(req),
      Number(req.params.id)
    );

    res.status(200).json({
      mensaje: resultado.Resultado === 'ELIMINADO'
        ? 'Producto eliminado correctamente.'
        : 'El producto tenía historial asociado y fue desactivado.',
      datos: { idProducto: resultado.IDProducto, resultado: resultado.Resultado }
    });
  } catch (error) {
    next(error);
  }
};