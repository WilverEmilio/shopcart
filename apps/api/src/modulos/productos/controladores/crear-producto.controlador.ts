import type { Request, Response, NextFunction } from 'express';
import { crearProductoServicio } from '../servicios/productos.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { DatosCrearProducto } from '../tipos/producto-crear.tipo';

export const crearProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const resultado = await crearProductoServicio(
      obtenerIdActor(req),
      req.body as DatosCrearProducto
    );

    res.status(201).json({
      mensaje: 'Producto creado correctamente.',
      datos: { idProducto: resultado.IDProducto }
    });
  } catch (error) {
    next(error);
  }
};