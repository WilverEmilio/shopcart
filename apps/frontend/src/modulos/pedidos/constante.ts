import type { EstadoAvance, EstadoPedido } from './tipos/pedido';

export const ESTADOS_PEDIDO: EstadoPedido[] = [
  'PAGADO', 'EN_PREPARACION', 'DESPACHADO', 'ENTREGADO', 'CANCELADO', 'DEVUELTO_PARCIAL', 'DEVUELTO',
] as const;

export const ETIQUETA_ESTADO: Record<EstadoPedido, string> = {
  PAGADO: 'Pagado',
  EN_PREPARACION: 'En preparación',
  DESPACHADO: 'Despachado',
  ENTREGADO: 'Entregado',
  CANCELADO: 'Cancelado',
  DEVUELTO_PARCIAL: 'Devuelto parcial',
  DEVUELTO: 'Devuelto',
};

export const CLASE_ESTADO: Record<EstadoPedido, string> = {
  PAGADO: 'bg-blue-100 text-blue-800',
  EN_PREPARACION: 'bg-amber-100 text-amber-800',
  DESPACHADO: 'bg-indigo-100 text-indigo-800',
  ENTREGADO: 'bg-green-100 text-green-800',
  CANCELADO: 'bg-gray-200 text-gray-700',
  DEVUELTO_PARCIAL: 'bg-orange-100 text-orange-800',
  DEVUELTO: 'bg-red-100 text-red-800',
};

export const ACCION_AVANCE: Record<EstadoAvance, string> = {
  EN_PREPARACION: 'Iniciar preparación',
  DESPACHADO: 'Marcar como despachado',
  ENTREGADO: 'Marcar como entregado',
};

export const esEstadoAvance = (estado: EstadoPedido): estado is EstadoAvance => estado in ACCION_AVANCE;

export const OPCIONES_ORDEN_PEDIDOS = [
  { valor: 'Fecha|DESC', etiqueta: 'Más recientes' },
  { valor: 'Fecha|ASC', etiqueta: 'Más antiguos' },
  { valor: 'Total|DESC', etiqueta: 'Total: mayor a menor' },
  { valor: 'Total|ASC', etiqueta: 'Total: menor a mayor' },
  { valor: 'Cliente|ASC', etiqueta: 'Cliente (A-Z)' },
  { valor: 'Estado|ASC', etiqueta: 'Estado' },
] as const;