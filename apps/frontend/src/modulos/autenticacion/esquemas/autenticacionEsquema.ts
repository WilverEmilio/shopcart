import { z } from 'zod';

const correo = z.string().trim().pipe(z.email('Ingresa un correo válido.'));

export const inicioSesionEsquema = z.object({
  correo,
  contrasena: z.string().min(1, 'Ingresa tu contraseña.'),
});

export type DatosInicioSesion = z.infer<typeof inicioSesionEsquema>;

export const registroEsquema = z
  .object({
    nombres: z.string().trim().min(1, 'Los nombres son obligatorios.').max(100, 'Máximo 100 caracteres.'),
    apellidos: z.string().trim().min(1, 'Los apellidos son obligatorios.').max(100, 'Máximo 100 caracteres.'),
    correo,
    telefono: z
      .string()
      .trim()
      .regex(/^[0-9+\-\s]{7,20}$/, 'El teléfono no es válido.')
      .or(z.literal('')),
    contrasena: z
      .string()
      .min(8, 'La contraseña debe tener al menos 8 caracteres.')
      .max(72, 'La contraseña no puede superar 72 caracteres.'),
    confirmarContrasena: z.string().min(1, 'Confirma tu contraseña.'),
  })
  .refine((d) => d.contrasena === d.confirmarContrasena, {
    message: 'Las contraseñas no coinciden.',
    path: ['confirmarContrasena'],
  });

export type DatosRegistro = z.infer<typeof registroEsquema>;