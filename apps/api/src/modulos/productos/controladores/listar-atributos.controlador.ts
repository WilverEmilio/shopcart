import { Request, Response, NextFunction } from 'express';
import { listarAtributosServicio } from '../servicios/atributos.servicio';

export const listarAtributosControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const atributos = await listarAtributosServicio();

    res.status(200).json({
      mensaje: 'Atributos obtenidos correctamente.',
      datos: atributos
    });
  } catch (error) {
    next(error);
  }
};