import { z } from 'zod';

export const idParametroEsquema = z.object({
    id: z.coerce.number().int().positive('El identificador no es válido.')
});

export const textoOpcional = (max: number) =>
    z.string().trim().max(max).nullish().transform(v => v || null);

export const booleanoTexto = z.enum([
    'true', 
    'false'
]). transform(v => v === 'true');

export const fechaIso = z.iso.date('La fecha debe tener formato AAAA-MM-DD.');
export const rangoFechasValido = (
    d: {
        fechaDesde?: string;
        fechaHasta?: string
    }): boolean => 
        !d.fechaDesde || !d.fechaHasta || d.fechaDesde <= d.fechaHasta;

export const cambiarEstadoEsquema = z.strictObject({ 
    activo: z.boolean() 
});