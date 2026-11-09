import { z } from 'zod';

const precioTexto = z
  .string()
  .trim()
  .regex(/^\d+(\.\d{1,2})?$/, 'Ingresa un precio válido (máximo 2 decimales).')
  .transform(Number)
  .pipe(z.number().positive('El precio debe ser mayor a cero.'));

const atributoEsquema = z.object({
  atributo: z.string().trim().min(1, 'Elige un atributo.'),
  valor: z.string().trim().min(1, 'Indica el valor.').max(50, 'Máximo 50 caracteres.'),
});

const atributosEsquema = z
  .array(atributoEsquema)
  .max(10, 'Máximo 10 atributos.')
  .refine((lista) => new Set(lista.map((a) => a.atributo)).size === lista.length, {
    message: 'Un atributo no puede repetirse en la misma variante.',
  });

const skuEsquema = z
  .string()
  .trim()
  .min(1, 'El SKU es obligatorio.')
  .max(50, 'Máximo 50 caracteres.')
  .regex(/^\S+$/, 'El SKU no puede tener espacios.');

export const varianteFormEsquema = z.object({
  sku: skuEsquema,
  precio: precioTexto,
  atributos: atributosEsquema,
});

export const varianteEdicionFormEsquema = z.object({
  sku: skuEsquema,
  atributos: atributosEsquema,
});

export const precioFormEsquema = z.object({ precio: precioTexto });

const urlImagenEsquema = z
  .string()
  .trim()
  .min(1, 'Ingresa la URL.')
  .max(500, 'Máximo 500 caracteres.')
  .regex(/^(https?:\/\/|\/)/, 'Usa una URL http(s) o una ruta que empiece con "/".');

export const imagenesFormEsquema = z.object({
  urls: z.array(urlImagenEsquema).max(20, 'Máximo 20 imágenes.'),
  principal: z.number().int().min(0),
});

export const datosProductoFormEsquema = z.object({
  idCategoria: z.string().regex(/^\d+$/, 'Elige una categoría.'),
  nombre: z.string().trim().min(1, 'El nombre es obligatorio.').max(150, 'Máximo 150 caracteres.'),
  descripcion: z.string().trim().max(4000, 'Máximo 4000 caracteres.'),
});

export const productoNuevoFormEsquema = datosProductoFormEsquema.extend({
  variantes: z
    .array(varianteFormEsquema)
    .min(1, 'Agrega al menos una variante.')
    .max(100, 'Máximo 100 variantes.')
    .refine((lista) => new Set(lista.map((v) => v.sku.toUpperCase())).size === lista.length, {
      message: 'Hay SKU repetidos dentro del producto.',
    }),
  imagenes: imagenesFormEsquema,
});

export const categoriaFormEsquema = z.object({
  nombre: z.string().trim().min(1, 'El nombre es obligatorio.').max(100, 'Máximo 100 caracteres.'),
  descripcion: z.string().trim().max(255, 'Máximo 255 caracteres.'),
});