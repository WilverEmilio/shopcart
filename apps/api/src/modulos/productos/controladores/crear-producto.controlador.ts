import type { Request, Response, NextFunction } from 'express';

import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { crearProductoServicio } from '../servicios/productos.servicio';

import type {
  DatosCrearProducto,
  VarianteCrear,
  ImagenProductoCrear
} from '../tipos/producto-crear.tipo';

export const crearProductoControlador = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const idUsuarioActor = req.usuarioAutenticado?.idUsuario;

    if (!idUsuarioActor) {
      throw new ErrorAplicacion(
        'No se pudo identificar al usuario autenticado.',
        50016,
        401
      );
    }

    const {
      idCategoria,
      nombre,
      descripcion,
      variantes,
      imagenes
    } = req.body;

    if (!Number.isInteger(idCategoria) || idCategoria <= 0) {
      throw new ErrorAplicacion(
        'La categoría seleccionada no es válida.',
        50053,
        400
      );
    }

    if (typeof nombre !== 'string' || nombre.trim().length === 0) {
      throw new ErrorAplicacion(
        'El nombre del producto es obligatorio.',
        50053,
        400
      );
    }

    if (nombre.trim().length > 150) {
      throw new ErrorAplicacion(
        'El nombre no puede superar los 150 caracteres.',
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

    if (!Array.isArray(variantes) || variantes.length === 0) {
      throw new ErrorAplicacion(
        'El producto debe tener al menos una variante.',
        50052,
        400
      );
    }

    for (const variante of variantes as VarianteCrear[]) {
      if (
        typeof variante.sku !== 'string' ||
        variante.sku.trim().length === 0 ||
        variante.sku.trim().length > 50 ||
        /\s/.test(variante.sku.trim())
      ) {
        throw new ErrorAplicacion(
          'Cada variante requiere un SKU válido de máximo 50 caracteres y sin espacios.',
          50053,
          400
        );
      }

      if (
        typeof variante.precio !== 'number' ||
        !Number.isFinite(variante.precio) ||
        variante.precio <= 0
      ) {
        throw new ErrorAplicacion(
          'El precio de cada variante debe ser mayor a cero.',
          50058,
          400
        );
      }

      if (
        variante.atributos !== undefined &&
        !Array.isArray(variante.atributos)
      ) {
        throw new ErrorAplicacion(
          'Los atributos de la variante no tienen un formato válido.',
          50053,
          400
        );
      }

      for (const atributo of variante.atributos ?? []) {
        if (
          typeof atributo.atributo !== 'string' ||
          !atributo.atributo.trim() ||
          atributo.atributo.trim().length > 50 ||
          typeof atributo.valor !== 'string' ||
          !atributo.valor.trim() ||
          atributo.valor.trim().length > 50
        ) {
          throw new ErrorAplicacion(
            'Cada atributo requiere un nombre y un valor válidos.',
            50053,
            400
          );
        }
      }
    }

    if (imagenes !== undefined && !Array.isArray(imagenes)) {
      throw new ErrorAplicacion(
        'Las imágenes deben enviarse en una lista.',
        50053,
        400
      );
    }

    const imagenesRecibidas = (imagenes ?? []) as ImagenProductoCrear[];

    let imagenPrincipal = 0;

    for (const imagen of imagenesRecibidas) {
      if (
        typeof imagen.url !== 'string' ||
        !imagen.url.trim() ||
        imagen.url.trim().length > 500 ||
        !(
          imagen.url.trim().startsWith('https://') ||
          imagen.url.trim().startsWith('http://') ||
          imagen.url.trim().startsWith('/')
        )
      ) {
        throw new ErrorAplicacion(
          'Cada imagen requiere una URL válida.',
          50053,
          400
        );
      }

      if (
        imagen.orden !== undefined &&
        (!Number.isInteger(imagen.orden) || imagen.orden < 0)
      ) {
        throw new ErrorAplicacion(
          'El orden de la imagen no es válido.',
          50053,
          400
        );
      }

      if (
        imagen.esPrincipal !== undefined &&
        typeof imagen.esPrincipal !== 'boolean'
      ) {
        throw new ErrorAplicacion(
          'El campo esPrincipal debe ser verdadero o falso.',
          50053,
          400
        );
      }

      if (imagen.esPrincipal === true) {
        imagenPrincipal++;
      }
    }

    if (imagenPrincipal > 1) {
      throw new ErrorAplicacion(
        'Solo puede existir una imagen principal.',
        50053,
        400
      );
    }

    const datos: DatosCrearProducto = {
      idCategoria,
      nombre: nombre.trim(),
      descripcion:
        typeof descripcion === 'string'
          ? descripcion.trim() || null
          : descripcion ?? null,
      variantes: variantes.map((variante: VarianteCrear) => ({
        ...variante,
        sku: variante.sku.trim().toUpperCase(),
        atributos: variante.atributos?.map((atributo) => ({
          atributo: atributo.atributo.trim(),
          valor: atributo.valor.trim()
        }))
      })),
      imagenes: imagenesRecibidas.map((imagen) => ({
        ...imagen,
        url: imagen.url.trim()
      }))
    };

    const resultado = await crearProductoServicio(
      idUsuarioActor,
      datos
    );

    res.status(201).json({
      mensaje: 'Producto creado correctamente.',
      datos: {
        idProducto: resultado.IDProducto
      }
    });
  } catch (error) {
    next(error);
  }
};