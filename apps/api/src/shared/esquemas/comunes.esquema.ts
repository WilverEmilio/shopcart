import { z } from 'zod';

export const idParametroEsquema = z.object({
    id: z.coerce.number().int().positive('El identificador no es válido.')
});

export const textoOpcional = (max: number) =>
    z.string().trim().max(max).nullish().transform(v => v || null);