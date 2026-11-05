import {z} from 'zod';

export const iniciarPagoEsquema = z.strictObject({
    idDireccion: z.number().int().positive(),
    idMetodoEnvio: z.number().int().positive(),
    totalEsperado: z.number().min(0).multipleOf(0.01).optional()
});

export const confirmarPagoEsquema = z.strictObject({
    tokenPago: z.string().trim().min(1, 'El token de pago es obligatorio ').max(50)
});