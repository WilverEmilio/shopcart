import { z } from 'zod';
import { fechaIso, rangoFechasValido } from '../../../shared/esquemas/comunes.esquema';

const rango = {
    fechaDesde: fechaIso.optional(),
    fechaHasta: fechaIso.optional()
};
const MSG_RANGO = { message: 'La fecha inicial no puede ser posterior a la final.', path: ['fechaDesde'] };

export const rangoQueryEsquema = z.object(rango).refine(rangoFechasValido, MSG_RANGO);

export const ventasPeriodoQueryEsquema = z.object({
    ...rango,
    agrupacion: z.enum(['DIA', 'SEMANA', 'MES']).default('DIA')
}).refine(rangoFechasValido, MSG_RANGO);

export const topProductosQueryEsquema = z.object({
    ...rango,
    top: z.coerce.number().int().min(1).max(50).default(10),
    ordenarPor: z.enum(['UNIDADES', 'VENTAS']).default('UNIDADES')
}).refine(rangoFechasValido, MSG_RANGO);

export const abandonadosQueryEsquema = z.object({
    ordenarPor: z.enum(['HorasInactivo', 'Valor', 'Unidades']).default('HorasInactivo'),
    direccion: z.enum(['ASC', 'DESC']).default('DESC'),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
});

export type RangoQuery = z.infer<typeof rangoQueryEsquema>;
export type VentasPeriodoQuery = z.infer<typeof ventasPeriodoQueryEsquema>;
export type TopProductosQuery = z.infer<typeof topProductosQueryEsquema>;
export type AbandonadosQuery = z.infer<typeof abandonadosQueryEsquema>;