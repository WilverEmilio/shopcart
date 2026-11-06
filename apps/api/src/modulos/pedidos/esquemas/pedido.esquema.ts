import {z} from 'zod';
import {fechaIso, rangoFechasValido, textoOpcional } from '../../../shared/esquemas/comunes.esquema';

export const estadoPedidos = [
    'PAGADO', 'EN_PREPARACION', 'DESPACHADO', 'ENTREGADO', 'CANCELADO', 'DEVUELTO_PARCIAL', 'DEVUELTO'
]as const;

export const misPedidosQueryEsquema = z.object({
    estado: z.enum(estadoPedidos).optional(),
    pagina: z.coerce.number().int().min(1).default(1),
    registroPorPagina: z.coerce.number().int().min(1).max(50).default(10)
});

export type MisPedidosQuery = z.infer<typeof misPedidosQueryEsquema>;

export const cancelarPedidoEsquema = z.strictObject({
    motivo: z.string().trim().min(1,'El motivo es obligatorio').max(255)
})

export const listarPedidosQueryEsquema = z.object({
    estado: z.enum(estadoPedidos).optional(),
    idCliente: z.coerce.number().int().positive().optional(),
    texto: z.string().trim().max(100).optional(),
    fechaDesde: fechaIso.optional(),
    fechaHasta: fechaIso.optional(),
    ordenarPor: z.enum(['Fecha', 'Total', 'Estado', 'Cliente']).default('Fecha'),
    direccion: z.enum(['ASC', 'DESC']).default('DESC'),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
}).refine(rangoFechasValido, { message: 'La fecha inicial no puede ser posterior a la final.', path: ['fechaDesde'] });
export type ListarPedidosQuery = z.infer<typeof listarPedidosQueryEsquema>;

export const avanzarEstadoEsquema = z.strictObject({
    estado: z.enum(['EN_PREPARACION', 'DESPACHADO', 'ENTREGADO']),
    comentario: textoOpcional(255)
});

export const devolucionEsquema = z.strictObject({
    motivo: z.string().trim().min(1, 'El motivo es obligatorio.').max(255),
    devolverTodo: z.boolean().default(false),
    lineas: z.array(z.strictObject({
        idDetallePedido: z.number().int().positive(),
        cantidad: z.number().int().positive()
    })).max(100).default([])
}).refine(d => d.devolverTodo || d.lineas.length > 0,
    { message: 'Indique las líneas a devolver o marque la devolución total.', path: ['lineas'] });