import { z } from 'zod';

export const direccionEsquema = z.object({
  nombreDestinatario: z.string().trim().min(1, 'El destinatario es obligatorio.').max(100, 'Máximo 100 caracteres.'),
  telefono: z.string().trim().regex(/^[0-9+\-\s]{7,20}$/, 'El teléfono no es válido.'),
  departamento: z.string().trim().min(1, 'El departamento es obligatorio.').max(50, 'Máximo 50 caracteres.'),
  municipio: z.string().trim().min(1, 'El municipio es obligatorio.').max(50, 'Máximo 50 caracteres.'),
  direccion: z.string().trim().min(1, 'La dirección es obligatoria.').max(250, 'Máximo 250 caracteres.'),
  referencia: z.string().trim().max(250, 'Máximo 250 caracteres.'),
  esPredeterminada: z.boolean(),
});

export type DatosFormularioDireccion = z.infer<typeof direccionEsquema>;