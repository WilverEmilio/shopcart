export type EstadoPedido = 
    | 'PAGADO'
    | 'EN_PREPARACION'
    | 'DESPACHADO'
    | 'ENTREGADO'
    | 'CANCELADO'
    | 'DEVUELTO_PARCIAL'
    | 'DEVUELTO';

export type EstadoAvance = 'EN_PREPARACION' | 'DESPACHADO' | 'ENTREGADO';

export interface PedidoResumenCliente {
    idPedido: number;
    numeroPedido: string;
    estado: EstadoPedido;
    total: number;
    unidades: number;
    fechaCreacion: string;
    fechaActualizacion: string;
}

export interface PedidoResumenGestion {
    idPedido: number;
    numeroPedido: string; 
    estado: EstadoPedido;
    idUsuario: number;
    correoCliente: string;
    nombreCliente: string;
    total: number;
    devuelto: number;
    nombreEnvio: string | null;
    codigoCupon: string | null;
    fechaCreacion: string;
    fechaActualizacion: string;
}

export interface LineaPedido {
    idDetallePedido: number;
    idVariante: number;
    sku: string;
    nombreProducto: string;
    atributos: string | null;
    precioUnitario: number;
    cantidad: number;
    subottal: number;
    descuentoLinea: number;
    cantidadDevuelta: number;
}

export interface HistorialPedido {
  idHistorial: number;
  estadoAnterior: EstadoPedido | null;
  estadoNuevo: EstadoPedido;
  fecha: string;
  comentario: string | null;
  idUsuario: number;
  correoUsuario: string;
}

export interface Devolucion {
  idDevolucion: number;
  fecha: string;
  motivo: string;
  montoReembolso: number;
  correoUsuario: string;
}

export interface LineaDevolucion {
  idDevolucion: number;
  idDetallePedido: number;
  sku: string;
  nombreProducto: string;
  cantidad: number;
  montoReembolso: number;
}

export interface DetallePedido {
  idPedido: number;
  numeroPedido: string;
  estado: EstadoPedido;
  idUsuario: number;
  correoCliente: string;
  nombreCliente: string;
  subtotal: number;
  descuento: number;
  costoEnvio: number;
  total: number;
  baseImponible: number;
  iva: number;
  codigoCupon: string | null;
  nombreEnvio: string | null;
  destinatarioEnvio: string;
  telefonoEnvio: string;
  departamentoEnvio: string;
  municipioEnvio: string;
  direccionEnvio: string;
  referenciaEnvio: string | null;
  fechaCreacion: string;
  fechaActualizacion: string;
  items: LineaPedido[];
  historial: HistorialPedido[];
  devoluciones: Devolucion[];
  detalleDevoluciones: LineaDevolucion[];
}

export interface Transicion {
  origen: EstadoPedido;
  destino: EstadoPedido;
}

export interface FiltrosMisPedidos {
  estado?: EstadoPedido;
  pagina?: number;
  registroPorPagina?: number;
}

export interface FiltrosPedidosGestion {
  estado?: EstadoPedido;
  texto?: string;
  fechaDesde?: string;
  fechaHasta?: string;
  ordenarPor?: 'Fecha' | 'Total' | 'Estado' | 'Cliente';
  direccion?: 'ASC' | 'DESC';
  pagina?: number;
  registrosPorPagina?: number;
}

export interface ResultadoCancelacion {
  idPedido: number;
  estado: EstadoPedido;
  cambio: boolean;
  montoReembolso: number;
}

export interface DatosDevolucion {
  motivo: string;
  devolverTodo: boolean;
  lineas: { idDetallePedido: number; cantidad: number }[];
}