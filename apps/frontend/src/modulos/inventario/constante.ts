import type { TipoMovimiento } from './tipos/inventario';

export const TIPOS_MOVIMIENTO: TipoMovimiento[] = ['ENTRADA', 'SALIDA', 'AJUSTE', 'DEVOLUCION', 'CANCELACION'];

export const ETIQUETA_MOVIMIENTO: Record<TipoMovimiento, string> = {
  ENTRADA: 'Entrada',
  SALIDA: 'Salida',
  AJUSTE: 'Ajuste',
  DEVOLUCION: 'Devolución',
  CANCELACION: 'Cancelación',
};

export const CLASE_MOVIMIENTO: Record<TipoMovimiento, string> = {
  ENTRADA: 'bg-green-100 text-green-800',
  SALIDA: 'bg-gray-200 text-gray-700',
  AJUSTE: 'bg-amber-100 text-amber-800',
  DEVOLUCION: 'bg-blue-100 text-blue-800',
  CANCELACION: 'bg-indigo-100 text-indigo-800',
};