import type { Request, Response, NextFunction } from 'express';
import { obtenerCatalogo } from '../servicios/catalogo.servicio';
import type { FiltrosCatalogo } from '../tipos/catalogo.tipo';

export const listarProductosControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const ordenarPorPermitidos = [
      'Nombre',
      'Precio',
      'FechaCreacion'
    ] as const;

    const ordenarPor =
      typeof req.query.ordenarPor === 'string' &&
      ordenarPorPermitidos.includes(
        req.query.ordenarPor as typeof ordenarPorPermitidos[number]
      )
        ? req.query.ordenarPor as FiltrosCatalogo['ordenarPor']
        : 'Nombre';

    const direccion: FiltrosCatalogo['direccion'] =
      req.query.direccion === 'DESC' ? 'DESC' : 'ASC';

    const filtros: FiltrosCatalogo = {
      texto: typeof req.query.texto === 'string'
        ? req.query.texto
        : undefined,

      idCategoria: req.query.idCategoria
        ? Number(req.query.idCategoria)
        : undefined,

      precioMin: req.query.precioMinimo
        ? Number(req.query.precioMinimo)
        : undefined,

      precioMax: req.query.precioMaximo
        ? Number(req.query.precioMaximo)
        : undefined,

      soloDisponibles: req.query.soloDisponibles === 'true',

      pagina: Number(req.query.pagina ?? 1),

      tamanoPagina: Number(req.query.registrosPorPagina ?? 20),

      ordenarPor,

      direccion
    };

    const idUsuarioActor =
      req.usuarioAutenticado?.idUsuario ?? null;

    const resultado = await obtenerCatalogo(
      filtros,
      idUsuarioActor
    );

    res.status(200).json({
      mensaje: 'Catálogo obtenido correctamente',
      datos: resultado
    });
  } catch (error) {
    next(error);
  }
};