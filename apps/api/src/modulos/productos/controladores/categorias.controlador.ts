import type { Request, Response, NextFunction } from 'express';
import {
  obtenerCategorias,
  actualizarCategoriaServicio,
  cambiarEstadoCategoriaServicio,
  obtenerCategoriasPublicas
} from '../servicios/categorias.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { CategoriasQuery } from '../esquemas/producto.esquema';

export const listarCategoriasControlador = async (
  req: Request, res: Response, next: NextFunction
): Promise<void> => {
  try {
    const q = req.query as unknown as CategoriasQuery;

    const resultado = await obtenerCategorias({
      busqueda: q.busqueda || undefined,
      activo: q.activo,
      ordenarPor: q.ordenarPor,
      direccion: q.direccion,
      pagina: q.pagina,
      tamanoPagina: q.registrosPorPagina
    });

    res.status(200).json({ mensaje: 'Categorías obtenidas correctamente', datos: resultado });
  } catch (error) {
    next(error);
  }
};

export const actualizarCategoriaControlador = async (
  req: Request, res: Response, next: NextFunction
): Promise<void> => {
  try {
    const idActualizado = await actualizarCategoriaServicio(
      obtenerIdActor(req),
      Number(req.params.id),
      req.body
    );

    res.status(200).json({
      mensaje: 'Categoría actualizada correctamente.',
      datos: { idCategoria: idActualizado }
    });
  } catch (error) {
    next(error);
  }
};

export const cambiarEstadoCategoriaControlador = async (
  req: Request, res: Response, next: NextFunction
): Promise<void> => {
  try {
    const resultado = await cambiarEstadoCategoriaServicio(
      obtenerIdActor(req),
      Number(req.params.id),
      req.body.activo as boolean
    );

    res.status(200).json({
      mensaje: resultado.Activo
        ? 'Categoría activada correctamente.'
        : 'Categoría desactivada correctamente.',
      datos: { idCategoria: resultado.IDCategoria, activo: resultado.Activo }
    });
  } catch (error) {
    next(error);
  }
};

export const listarCategoriasPublicasControlador = async (
  _req: Request, 
  res: Response, 
  next: NextFunction
): Promise<void> => {
  try {
    const datos = await obtenerCategoriasPublicas();
    res.status(200).json({ 
      mensaje: 'Categorías obtenidas correctamente', 
      datos 
    });
  } catch (error) {
    next(error);
  }
};