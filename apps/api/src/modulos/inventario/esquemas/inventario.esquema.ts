import { z } from 'zod';
import { booleanoTexto, fechaIso, rangoFechasValido } from '../../../shared/esquemas/comunes.esquema';

const paginacion = {
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
};

const motivo = z.string().trim().min(1, 'El motivo es obligatorio.').max(255);

export const existenciasQueryEsquema = z.object({
    texto: z.string().trim().max(100).optional(),
    idCategoria: z.coerce.number().int().positive().optional(),
    soloSinDisponibilidad: booleanoTexto.default(false),
    activo: booleanoTexto.optional(),
    ordenarPor: z.enum(['SKU', 'Producto', 'Disponible']).default('Producto'),
    direccion: z.enum(['ASC', 'DESC']).default('ASC'),
    ...paginacion
});
export type ExistenciasQuery = z.infer<typeof existenciasQueryEsquema>;

export const kardexQueryEsquema = z.object({
    idVariante: z.coerce.number().int().positive().optional(),
    tipoMovimiento: z.enum(['ENTRADA', 'SALIDA', 'AJUSTE', 'DEVOLUCION', 'CANCELACION']).optional(),
    fechaDesde: fechaIso.optional(),
    fechaHasta: fechaIso.optional(),
    texto: z.string().trim().max(100).optional(),
    ...paginacion
}).refine(rangoFechasValido, { message: 'La fecha inicial no puede ser posterior a la final.', path: ['fechaDesde'] });
export type KardexQuery = z.infer<typeof kardexQueryEsquema>;

export const conciliacionQueryEsquema = z.object({
    soloDiferencias: booleanoTexto.default(true),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(200).default(50)
});
export type ConciliacionQuery = z.infer<typeof conciliacionQueryEsquema>;

export const entradaEsquema = z.strictObject({
    idVariante: z.number().int().positive(),
    cantidad: z.number().int().positive('La cantidad debe ser mayor a cero.').max(100000),
    motivo
});

export const ajusteEsquema = z.strictObject({
    idVariante: z.number().int().positive(),
    // Con signo: positiva suma, negativa resta
    cantidad: z.number().int().min(-100000).max(100000).refine(v => v !== 0, 'El ajuste no puede ser cero.'),
    motivo
});