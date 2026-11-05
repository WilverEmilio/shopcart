import { z } from 'zod';
import { textoOpcional } from '../../../shared/esquemas/comunes.esquema';

export const direccionEsquema = z.strictObject({
    nombreDestinatario: z.string().trim().min(1, 'El destinatario es obligatorio.').max(100),
    telefono: z.string().trim().regex(/^[0-9+\-\s]{7,20}$/, 'El teléfono no es válido.'),
    departamento: z.string().trim().min(1, 'El departamento es obligatorio.').max(50),
    municipio: z.string().trim().min(1, 'El municipio es obligatorio.').max(50),
    direccion: z.string().trim().min(1, 'La dirección es obligatoria.').max(250),
    referencia: textoOpcional(250),
    esPredeterminada: z.boolean().default(false)
});