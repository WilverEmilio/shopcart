import type { Request, Response, NextFunction } from 'express';
import { crearCategoriaServicio } from '../servicios/categoria-crear.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';

export const crearCategoriaControlador = async (
  req: Request, res: Response, next: NextFunction
): Promise<void> => {
  try {
    const idCategoria = await crearCategoriaServicio(
      obtenerIdActor(req),
      req.body.nombre,
      req.body.descripcion
    );

    res.status(201).json({ mensaje: 'Categoría creada correctamente', datos: { idCategoria } });
  } catch (error) {
    next(error);
  }
};