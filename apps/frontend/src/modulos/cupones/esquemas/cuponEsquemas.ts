import { z } from 'zod';

const decimalPositivo = z
  .string()
  .trim()
  .regex(/^\d+(\.\d{1,2})?$/, 'Ingresa un número válido (máximo 2 decimales).')
  .transform(Number)
  .pipe(z.number().positive('Debe ser mayor a cero.'));

const decimalNoNegativo = z
  .string()
  .trim()
  .regex(/^(\d+(\.\d{1,2})?)?$/, 'Ingresa un número válido (máximo 2 decimales).')
  .transform((v) => (v === '' ? 0 : Number(v)));

const enteroOpcional = z
  .string()
  .trim()
  .regex(/^\d*$/, 'Ingresa un número entero.')
  .transform((v) => (v === '' ? null : Number(v)))
  .pipe(z.number().int().positive('Debe ser mayor a cero.').nullable());

const fechaHoraLocal = z
  .string()
  .min(1, 'Indica la fecha y la hora.')
  .refine((v) => !Number.isNaN(new Date(v).getTime()), 'La fecha no es válida.')
  .transform((v) => new Date(v).toISOString());

const camposComunes = z.object({
  descripcion: z.string().trim().max(255, 'Máximo 255 caracteres.'),
  tipoDescuento: z.enum(['PORCENTAJE', 'MONTO_FIJO']),
  valor: decimalPositivo,
  idCategoria: z.string().regex(/^\d*$/).transform((v) => (v === '' ? null : Number(v))),
  montoMinimo: decimalNoNegativo,
  fechaInicio: fechaHoraLocal,
  fechaFin: fechaHoraLocal,
  limiteUsosTotal: enteroOpcional,
  limiteUsosPorCliente: enteroOpcional,
});

const codigo = z
  .string()
  .trim()
  .min(3, 'Mínimo 3 caracteres.')
  .max(30, 'Máximo 30 caracteres.')
  .regex(/^[A-Za-z0-9_-]+$/, 'Solo letras, números, guion y guion bajo.');

type Cruzados = { tipoDescuento: string; valor: number; fechaInicio: string; fechaFin: string };

const vigenciaValida = (d: Cruzados) => d.fechaFin > d.fechaInicio;
const porcentajeValido = (d: Cruzados) => d.tipoDescuento !== 'PORCENTAJE' || d.valor <= 100;

const MSG_VIGENCIA = { message: 'La fecha de fin debe ser posterior a la de inicio.', path: ['fechaFin'] };
const MSG_PORCENTAJE = { message: 'El porcentaje no puede superar 100.', path: ['valor'] };

export const cuponNuevoFormEsquema = camposComunes
  .extend({ codigo })
  .refine(vigenciaValida, MSG_VIGENCIA)
  .refine(porcentajeValido, MSG_PORCENTAJE);

export const cuponEdicionFormEsquema = camposComunes
  .refine(vigenciaValida, MSG_VIGENCIA)
  .refine(porcentajeValido, MSG_PORCENTAJE);