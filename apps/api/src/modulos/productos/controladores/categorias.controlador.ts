import type { Request, Response, NextFunction } from 'express';
import { obtenerCategorias } from '../servicios/categorias.servicio';
import type { FiltrosCategorias } from '../tipos/categoria.tipo';

export const listarCategoriasControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ordenarPorPermitidos = [
      'Nombre',
      'FechaCreacion'
    ] as const;

    const ordenarPor =
      typeof req.query.ordenarPor === 'string' &&
      ordenarPorPermitidos.includes(
        req.query.ordenarPor as typeof ordenarPorPermitidos[number]
      )
        ? req.query.ordenarPor as FiltrosCategorias['ordenarPor']
        : 'Nombre';

    const direccion: FiltrosCategorias['direccion'] =
      req.query.direccion === 'DESC' ? 'DESC' : 'ASC';

    const activo =
      req.query.activo === 'true'
        ? true
        : req.query.activo === 'false'
          ? false
          : undefined;

    const pagina = Number(req.query.pagina ?? 1);
    const tamanoPagina = Number(req.query.registrosPorPagina ?? 20);

    if (
      !Number.isInteger(pagina) ||
      pagina < 1 ||
      !Number.isInteger(tamanoPagina) ||
      tamanoPagina < 1 ||
      tamanoPagina > 100
    ) {
      res.status(400).json({
        mensaje: 'Los parámetros de paginación no son válidos'
      });
      return;
    }

    const busqueda =
      typeof req.query.busqueda === 'string'
        ? req.query.busqueda.trim()
        : undefined;

    if (busqueda !== undefined && busqueda.length > 100) {
      res.status(400).json({
        mensaje: 'La búsqueda no puede superar los 100 caracteres'
      });
      return;
    }

    const filtros: FiltrosCategorias = {
      busqueda: busqueda || undefined,
      activo,
      ordenarPor,
      direccion,
      pagina,
      tamanoPagina
    };

    const resultado = await obtenerCategorias(filtros);

    res.status(200).json({
      mensaje: 'Categorías obtenidas correctamente',
      datos: resultado
    });
  } catch (error) {
    next(error);
  }
};