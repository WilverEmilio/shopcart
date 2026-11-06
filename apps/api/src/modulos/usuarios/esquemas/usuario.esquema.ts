import { z } from 'zod';
import { booleanoTexto } from '../../../shared/esquemas/comunes.esquema';

export const usuariosQueryEsquema = z.object({
    busqueda: z.string().trim().max(100).optional(),
    idRol: z.coerce.number().int().positive().optional(),
    activo: booleanoTexto.optional(),
    ordenarPor: z.enum(['Correo', 'Nombres', 'FechaCreacion']).default('FechaCreacion'),
    direccion: z.enum(['ASC', 'DESC']).default('DESC'),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
});
export type UsuariosQuery = z.infer<typeof usuariosQueryEsquema>;

export const crearUsuarioInternoEsquema = z.strictObject({
    correo: z.email('El correo no es válido.').max(255).transform(v => v.trim().toLowerCase()),
    contrasena: z.string()
        .min(8, 'La contraseña debe tener al menos 8 caracteres.')
        .max(72, 'La contraseña no puede superar 72 caracteres.'),
    nombres: z.string().trim().min(1, 'Los nombres son obligatorios.').max(100),
    apellidos: z.string().trim().min(1, 'Los apellidos son obligatorios.').max(100),
    telefono: z.string().trim().regex(/^[0-9+\-\s]{7,20}$/, 'El teléfono no es válido.')
        .nullish().transform(v => v ?? null),
    rol: z.enum(['Operador', 'Administrador'])
});