export interface RangoFechas {
  fechaDesde: string;
  fechaHasta: string;
}

export type Agrupacion = 'DIA' | 'SEMANA' | 'MES';
export type OrdenTop = 'UNIDADES' | 'VENTAS';

export interface ResumenDashboard {
  fechaDesde: string;
  fechaHasta: string;
  pedidos: number;
  ventasBrutas: number;
  devoluciones: number;
  ventasNetas: number;
  ticketPromedio: number;
  unidadesNetas: number;
  pedidosCancelados: number;
  montoCancelado: number;
  pedidosAnterior: number;
  ventasNetasAnterior: number;
  carritosAbandonados: number;
  valorCarritosAbandonados: number;
}

export interface FilaVentasPeriodo {
  periodoInicio: string;
  etiqueta: string;
  pedidos: number;
  ventasBrutas: number;
  devoluciones: number;
  ventasNetas: number;
  ticketPromedio: number;
}

export interface FilaVentasCategoria {
  idCategoria: number;
  categoria: string;
  unidades: number;
  ventasNetas: number;
  pedidos: number;
  porcentaje: number;
}

export interface FilaTopProducto {
  ranking: number;
  idProducto: number;
  producto: string;
  categoria: string;
  unidades: number;
  ventasNetas: number;
}

export interface FiltrosAbandonados {
  ordenarPor?: 'HorasInactivo' | 'Valor' | 'Unidades';
  direccion?: 'ASC' | 'DESC';
  pagina?: number;
  registrosPorPagina?: number;
}

export interface CarritoAbandonado {
  idCarrito: number;
  cliente: string | null;
  esInvitado: boolean;
  lineas: number;
  unidades: number;
  valor: number;
  fechaCreacion: string;
  fechaActualizacion: string;
  horasInactivo: number;
}

export interface ResultadoAbandonados {
  items: CarritoAbandonado[];
  pagina: number;
  tamanoPagina: number;
  totalRegistros: number;
  valorTotal: number;
}