import { z } from 'zod';
import { textoOpcional } from '../../../shared/esquemas/comunes.esquema';

const fechaHora = z.iso
    .datetime('La fecha debe tener formato ISO en UTC (AAAA-MM-DDTHH:mm:ssZ).')
    .transform(v => new Date(v));

const enteroOpcional = z.number().int().positive().nullish().transform(v => v ?? null);

const campos = {
    descripcion: textoOpcional(255),
    tipoDescuento: z.enum(['PORCENTAJE', 'MONTO_FIJO']),
    valor: z.number().positive('El valor debe ser mayor a cero.').multipleOf(0.01),
    idCategoria: enteroOpcional,
    montoMinimo: z.number().min(0).multipleOf(0.01).default(0),
    fechaInicio: fechaHora,
    fechaFin: fechaHora,
    limiteUsosTotal: enteroOpcional,
    limiteUsosPorCliente: enteroOpcional
};

const vigenciaValida = (d: { fechaInicio: Date; fechaFin: Date }) => d.fechaFin > d.fechaInicio;
const porcentajeValido = (d: { tipoDescuento: string; valor: number }) =>
    d.tipoDescuento !== 'PORCENTAJE' || d.valor <= 100;

const MSG_VIGENCIA = { message: 'La fecha de fin debe ser posterior a la de inicio.', path: ['fechaFin'] };
const MSG_PORCENTAJE = { message: 'El porcentaje no puede superar 100.', path: ['valor'] };

export const crearCuponEsquema = z.strictObject({
    codigo: z.string().trim().min(3).max(30)
        .regex(/^[A-Za-z0-9_-]+$/, 'El código solo admite letras, números, guion y guion bajo.')
        .transform(v => v.toUpperCase()),
    ...campos
}).refine(vigenciaValida, MSG_VIGENCIA).refine(porcentajeValido, MSG_PORCENTAJE);

// El código no se puede cambiar una vez creado
export const actualizarCuponEsquema = z.strictObject(campos)
    .refine(vigenciaValida, MSG_VIGENCIA).refine(porcentajeValido, MSG_PORCENTAJE);

export const cuponesQueryEsquema = z.object({
    busqueda: z.string().trim().max(100).optional(),
    estado: z.enum(['INACTIVO', 'PROGRAMADO', 'VENCIDO', 'AGOTADO', 'VIGENTE']).optional(),
    idCategoria: z.coerce.number().int().positive().optional(),
    ordenarPor: z.enum(['Codigo', 'FechaFin', 'UsosActuales', 'FechaCreacion']).default('FechaFin'),
    direccion: z.enum(['ASC', 'DESC']).default('DESC'),
    pagina: z.coerce.number().int().min(1).default(1),
    registrosPorPagina: z.coerce.number().int().min(1).max(100).default(20)
});
export type CuponesQuery = z.infer<typeof cuponesQueryEsquema>;