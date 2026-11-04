import { z } from 'zod';

const booleanoTexto = z.enum(['true', 'false']).transform(v => v === 'true');

export const catalogoQueryEsquema = z.object({
    texto: z.string().trim().max(100).optional(),
    idCategoria: z.coerce.number().int().positive().optional(),
    precioMinimo: z.coerce.number().min(0).optional(),
    precioMaximo: z.coerce.number().min(0).optional(),
    soloDisponibles: booleanoTexto.default(false),
    activo: booleanoTexto.optional(),
    ordenarPor: z.enum(['Nombre', 'Precio', 'FechaCreacion']).default('Nombre'),
    direccion: z.enum(['ASC', 'DESC']).default('ASC'),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
}).refine(
    d => d.precioMinimo === undefined || d.precioMaximo === undefined || d.precioMinimo <= d.precioMaximo,
    { message: 'El precio mínimo no puede ser mayor al máximo.', path: ['precioMinimo'] }
);

export type CatalogoQuery = z.infer<typeof catalogoQueryEsquema>;