import type { EstadoCupon } from './tipos/cupon';

export const ESTADOS_CUPON: EstadoCupon[] = ['VIGENTE', 'PROGRAMADO', 'AGOTADO', 'VENCIDO', 'INACTIVO'];

export const ETIQUETA_ESTADO_CUPON: Record<EstadoCupon, string> = {
  VIGENTE: 'Vigente',
  PROGRAMADO: 'Programado',
  AGOTADO: 'Agotado',
  VENCIDO: 'Vencido',
  INACTIVO: 'Inactivo',
};

export const CLASE_ESTADO_CUPON: Record<EstadoCupon, string> = {
  VIGENTE: 'bg-green-100 text-green-800',
  PROGRAMADO: 'bg-blue-100 text-blue-800',
  AGOTADO: 'bg-amber-100 text-amber-800',
  VENCIDO: 'bg-slate-200 text-slate-700',
  INACTIVO: 'bg-slate-300 text-slate-700',
};

const dosDigitos = (n: number) => String(n).padStart(2, '0');

export const aInputLocal = (fecha: Date): string =>
  `${fecha.getFullYear()}-${dosDigitos(fecha.getMonth() + 1)}-${dosDigitos(fecha.getDate())}T${dosDigitos(fecha.getHours())}:${dosDigitos(fecha.getMinutes())}`;