import { z } from 'zod';

const cantidad = z.number().int().positive('La cantidad debe ser mayor a cero.').max(999);

export const agregarItemEsquema = z.strictObject({
    idVariante: z.number().int().positive(),
    cantidad
});

export const actualizarCantidadEsquema = z.strictObject({ cantidad });

export const idVarianteParametroEsquema = z.object({
    idVariante: z.coerce.number().int().positive('El identificador no es válido.')
});

export const aplicarCuponEsquema = z.strictObject({
    codigo: z.string().trim().min(3).max(30)
        .regex(/^[A-Za-z0-9_-]+$/, 'El código del cupón no es válido.')
        .transform(v => v.toUpperCase())
});