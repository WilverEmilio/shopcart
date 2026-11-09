import { z } from 'zod';

export const usuarioNuevoFormEsquema = z.object({
  correo: z.string().trim().pipe(z.email('Ingresa un correo válido.')),
  contrasena: z
    .string()
    .min(8, 'La contraseña debe tener al menos 8 caracteres.')
    .max(72, 'La contraseña no puede superar 72 caracteres.'),
  nombres: z.string().trim().min(1, 'Los nombres son obligatorios.').max(100, 'Máximo 100 caracteres.'),
  apellidos: z.string().trim().min(1, 'Los apellidos son obligatorios.').max(100, 'Máximo 100 caracteres.'),
  telefono: z
    .string()
    .trim()
    .regex(/^[0-9+\-\s]{7,20}$/, 'El teléfono no es válido.')
    .or(z.literal('')),
  rol: z.enum(['Operador', 'Administrador']),
});