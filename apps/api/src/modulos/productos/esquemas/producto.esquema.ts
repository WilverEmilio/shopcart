import { z } from 'zod';
import { textoOpcional } from '../../../shared/esquemas/comunes.esquema';

const atributo = z.strictObject({
    atributo: z.string().trim().min(1).max(50),
    valor: z.string().trim().min(1).max(50)
});

const variante = z.strictObject({
    sku: z.string().trim().min(1).max(50).regex(/^\S+$/, 'El SKU no puede tener espacios.')
        .transform(v => v.toUpperCase()),
    precio: z.number().positive('El precio debe ser mayor a cero.').multipleOf(0.01, 'El precio admite máximo 2 decimales.'),
    atributos: z.array(atributo).max(10).default([])
});

const imagen = z.strictObject({
    url: z.string().trim().max(500).regex(/^(https?:\/\/|\/)/, 'La URL de la imagen no es válida.'),
    orden: z.number().int().min(0).optional(),
    esPrincipal: z.boolean().optional()
});

export const crearProductoEsquema = z.strictObject({
    idCategoria: z.number().int().positive(),
    nombre: z.string().trim().min(1, 'El nombre es obligatorio.').max(150),
    descripcion: textoOpcional(4000),
    variantes: z.array(variante).min(1, 'El producto debe tener al menos una variante.').max(100),
    imagenes: z.array(imagen).max(20).default([])
}).refine(d => d.imagenes.filter(i => i.esPrincipal).length <= 1,
    { message: 'Solo puede existir una imagen principal.', path: ['imagenes'] });

export const actualizarProductoEsquema = z.strictObject({
    idCategoria: z.number().int().positive(),
    nombre: z.string().trim().min(1, 'El nombre es obligatorio.').max(150),
    descripcion: textoOpcional(4000)
});

export const cambiarEstadoEsquema = z.strictObject({ activo: z.boolean() });

export const categoriaEsquema = z.strictObject({
    nombre: z.string().trim().min(1, 'El nombre es obligatorio.').max(100),
    descripcion: textoOpcional(255)
});

export const categoriasQueryEsquema = z.object({
    busqueda: z.string().trim().max(100).optional(),
    activo: z.enum(['true', 'false']).transform(v => v === 'true').optional(),
    ordenarPor: z.enum(['Nombre', 'FechaCreacion']).default('Nombre'),
    direccion: z.enum(['ASC', 'DESC']).default('ASC'),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
});

export type CategoriasQuery = z.infer<typeof categoriasQueryEsquema>;