import type { Request, Response, NextFunction } from 'express';
import { actualizarProductoServicio } from '../servicios/productos.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { DatosActualizarProducto } from '../tipos/producto-actualizar.tipo';

export const actualizarProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const resultado = await actualizarProductoServicio(
      obtenerIdActor(req),
      Number(req.params.id),
      req.body as DatosActualizarProducto
    );

    res.status(200).json({
      mensaje: 'Producto actualizado correctamente.',
      datos: { idProducto: resultado.IDProducto }
    });
  } catch (error) {
    next(error);
  }
};