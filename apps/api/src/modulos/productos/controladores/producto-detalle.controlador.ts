import type { Request, Response, NextFunction } from 'express';
import { ObtenerDetalleProductoServicio } from '../servicios/producto-detalle.servicio';

export const obtenerDetalleProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const resultado = await ObtenerDetalleProductoServicio(
      Number(req.params.id),
      req.usuarioAutenticado?.idUsuario ?? null
    );

    res.status(200).json({
      mensaje: 'Detalle del producto obtenido correctamente',
      datos: resultado
    });
  } catch (error) {
    next(error);
  }
};