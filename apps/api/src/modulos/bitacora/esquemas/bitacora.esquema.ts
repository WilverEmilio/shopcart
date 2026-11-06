import { z } from 'zod';
import { fechaIso, rangoFechasValido } from '../../../shared/esquemas/comunes.esquema';

export const modulosBitacora = ['Usuarios', 'Catalogo', 'Productos', 'Precios', 'Inventario', 'Cupones', 'Pedidos', 'Configuracion'] as const;

export const bitacoraQueryEsquema = z.object({
    modulo: z.enum(modulosBitacora).optional(),
    idUsuario: z.coerce.number().int().positive().optional(),
    fechaDesde: fechaIso.optional(),
    fechaHasta: fechaIso.optional(),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
}).refine(rangoFechasValido, { message: 'La fecha inicial no puede ser posterior a la final.', path: ['fechaDesde'] });
export type BitacoraQuery = z.infer<typeof bitacoraQueryEsquema>;