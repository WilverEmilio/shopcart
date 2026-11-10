import type { TipoMovimiento } from './tipos/inventario';

export const TIPOS_MOVIMIENTO: TipoMovimiento[] = [
  'ENTRADA', 
  'SALIDA', 
  'AJUSTE', 
  'DEVOLUCION', 
  'CANCELACION'
] as const;

export const ETIQUETA_MOVIMIENTO: Record<TipoMovimiento, string> = {
  ENTRADA: 'Entrada',
  SALIDA: 'Salida',
  AJUSTE: 'Ajuste',
  DEVOLUCION: 'Devolución',
  CANCELACION: 'Cancelación',
};

export const CLASE_MOVIMIENTO: Record<TipoMovimiento, string> = {
  ENTRADA: 'bg-green-100 text-green-800',
  SALIDA: 'bg-slate-200 text-slate-700',
  AJUSTE: 'bg-amber-100 text-amber-800',
  DEVOLUCION: 'bg-blue-100 text-blue-800',
  CANCELACION: 'bg-marca-100 text-marca-800',
};

export const OPCIONES_ORDEN_EXISTENCIAS = [
  { valor: 'Producto|ASC', etiqueta: 'Producto (A-Z)' },
  { valor: 'Producto|DESC', etiqueta: 'Producto (Z-A)' },
  { valor: 'SKU|ASC', etiqueta: 'SKU (A-Z)' },
  { valor: 'SKU|DESC', etiqueta: 'SKU (Z-A)' },
  { valor: 'Disponible|ASC', etiqueta: 'Disponible: menor a mayor' },
  { valor: 'Disponible|DESC', etiqueta: 'Disponible: mayor a menor' },
] as const;