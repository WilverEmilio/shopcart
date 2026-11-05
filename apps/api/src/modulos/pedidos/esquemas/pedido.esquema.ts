import {z} from 'zod';

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