import type { RangoFechas } from './tipos/reportes';

const dosDigitos = (n: number) => String(n).padStart(2, '0');

export const aIsoLocal = (fecha: Date): string =>
  `${fecha.getFullYear()}-${dosDigitos(fecha.getMonth() + 1)}-${dosDigitos(fecha.getDate())}`;

export function rangoUltimosDias(dias: number): RangoFechas {
  const hasta = new Date();
  const desde = new Date();
  desde.setDate(desde.getDate() - (dias - 1));
  return { fechaDesde: aIsoLocal(desde), fechaHasta: aIsoLocal(hasta) };
}

export const PRESETS_RANGO = [
  { dias: 7, etiqueta: 'Últimos 7 días' },
  { dias: 30, etiqueta: 'Últimos 30 días' },
  { dias: 90, etiqueta: 'Últimos 90 días' },
] as const;

export const diasEntre = (desde: string, hasta: string): number =>
  Math.round((new Date(`${hasta}T00:00:00`).getTime() - new Date(`${desde}T00:00:00`).getTime()) / 86_400_000);