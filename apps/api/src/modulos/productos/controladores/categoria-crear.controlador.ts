import type { Request, Response, NextFunction } from 'express';

import { crearCategoriaServicio } from '../servicios/categoria-crear.servicio';

export const crearCategoriaControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { nombre, descripcion } = req.body;

    const idUsuarioActor = req.usuarioAutenticado?.idUsuario;

    if (!idUsuarioActor) {
      res.status(401).json({
        mensaje: 'No se pudo identificar al usuario autenticado'
      });
      return;
    }

    if (
      typeof nombre !== 'string' ||
      nombre.trim().length === 0 ||
      nombre.trim().length > 100
    ) {
      res.status(400).json({
        mensaje: 'El nombre es obligatorio y debe tener máximo 100 caracteres'
      });
      return;
    }

    if (
      descripcion !== undefined &&
      descripcion !== null &&
      (
        typeof descripcion !== 'string' ||
        descripcion.length > 255
      )
    ) {
      res.status(400).json({
        mensaje: 'La descripción debe ser un texto de máximo 255 caracteres'
      });
      return;
    }

    const nombreLimpio = nombre.trim();

    const descripcionLimpia =
      typeof descripcion === 'string'
        ? descripcion.trim() || null
        : null;

    const idCategoria = await crearCategoriaServicio(
      idUsuarioActor,
      nombreLimpio,
      descripcionLimpia
    );

    res.status(201).json({
      mensaje: 'Categoría creada correctamente',
      datos: {
        idCategoria
      }
    });
  } catch (error) {
    next(error);
  }
};