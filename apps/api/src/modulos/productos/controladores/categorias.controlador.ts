import type { Request, Response, NextFunction } from 'express';
import { obtenerCategorias } from '../servicios/categorias.servicio';
import type { FiltrosCategorias } from '../tipos/categoria.tipo';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { actualizarCategoriaServicio } from '../servicios/categorias.servicio';
import { cambiarEstadoCategoriaServicio } from '../servicios/categorias.servicio';

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

export const actualizarCategoriaControlador = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const idCategoria = Number(req.params.id);
        const idUsuarioActor = req.usuarioAutenticado?.idUsuario;

        const { nombre, descripcion } = req.body;

        if (!Number.isInteger(idCategoria) || idCategoria <= 0) {
            throw new ErrorAplicacion(
                'El ID de la categoría no es válido.',
                50053,
                400
            );
        }

        if (!idUsuarioActor) {
            throw new ErrorAplicacion(
                'No se pudo identificar al usuario autenticado.',
                50016,
                401
            );
        }

        if (typeof nombre !== 'string' || nombre.trim().length === 0) {
            throw new ErrorAplicacion(
                'El nombre de la categoría es obligatorio.',
                50053,
                400
            );
        }

        if (nombre.trim().length > 100) {
            throw new ErrorAplicacion(
                'El nombre no puede superar los 100 caracteres.',
                50053,
                400
            );
        }

        if (
            descripcion !== undefined &&
            descripcion !== null &&
            typeof descripcion !== 'string'
        ) {
            throw new ErrorAplicacion(
                'La descripción debe ser un texto.',
                50053,
                400
            );
        }

        if (
            typeof descripcion === 'string' &&
            descripcion.trim().length > 255
        ) {
            throw new ErrorAplicacion(
                'La descripción no puede superar los 255 caracteres.',
                50053,
                400
            );
        }

        const idActualizado = await actualizarCategoriaServicio(
            idUsuarioActor,
            idCategoria,
            {
                nombre: nombre.trim(),
                descripcion:
                    typeof descripcion === 'string'
                        ? descripcion.trim() || null
                        : descripcion ?? null
            }
        );

        res.status(200).json({
            mensaje: 'Categoría actualizada correctamente.',
            datos: {
                idCategoria: idActualizado
            }
        });
    } catch (error) {
        next(error);
    }
};

export const cambiarEstadoCategoriaControlador = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const idCategoria = Number(req.params.id);
        const idUsuarioActor = req.usuarioAutenticado?.idUsuario;
        const { activo } = req.body;

        if (!Number.isInteger(idCategoria) || idCategoria <= 0) {
            throw new ErrorAplicacion(
                'El ID de la categoría no es válido.',
                50053,
                400
            );
        }

        if (!idUsuarioActor) {
            throw new ErrorAplicacion(
                'No se pudo identificar al usuario autenticado.',
                50016,
                401
            );
        }

        if (typeof activo !== 'boolean') {
            throw new ErrorAplicacion(
                'El campo activo debe ser verdadero o falso.',
                50053,
                400
            );
        }

        const resultado = await cambiarEstadoCategoriaServicio(
            idUsuarioActor,
            idCategoria,
            activo
        );

        res.status(200).json({
            mensaje: resultado.Activo
                ? 'Categoría activada correctamente.'
                : 'Categoría desactivada correctamente.',
            datos: {
                idCategoria: resultado.IDCategoria,
                activo: resultado.Activo
            }
        });
    } catch (error) {
        next(error);
    }
};