import { z } from 'zod';

export const registroClienteEsquema = z.strictObject({
    correo: z.email('El correo no es válido.').max(255).transform(v => v.trim().toLowerCase()),
    contrasena: z.string()
        .min(8, 'La contraseña debe tener al menos 8 caracteres.')
        .max(72, 'La contraseña no puede superar 72 caracteres.'),
    nombres: z.string().trim().min(1, 'Los nombres son obligatorios.').max(100),
    apellidos: z.string().trim().min(1, 'Los apellidos son obligatorios.').max(100),
    telefono: z.string().trim().regex(/^[0-9+\-\s]{7,20}$/, 'El teléfono no es válido.')
        .nullish().transform(v => v ?? null)
});

export const inicioSesionEsquema = z.strictObject({
    correo: z.email('El correo no es válido.').transform(v => v.trim().toLowerCase()),
    contrasena: z.string().min(1, 'La contraseña es obligatoria.').max(72)
});

export const tokenRefrescoEsquema = z.strictObject({
    tokenRefresco: z.string().regex(/^[0-9a-f]{64}$/, 'El token de refresco no es válido.')
});