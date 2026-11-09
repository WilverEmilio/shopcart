export type TipoMovimiento = 'ENTRADA' | 'SALIDA' | 'AJUSTE' | 'DEVOLUCION' | 'CANCELACION';

export interface ExistenciaVariante {
  idVariante: number;
  sku: string;
  idProducto: number;
  producto: string;
  idCategoria: number;
  categoria: string;
  existenciaFisica: number;
  existenciaReservada: number;
  existenciaDisponible: number;
  activo: boolean;
}

export interface MovimientoKardex {
  idMovimiento: number;
  fecha: string;
  tipoMovimiento: TipoMovimiento;
  cantidad: number;
  existenciaResultante: number;
  motivo: string;
  tipoReferencia: 'PEDIDO' | 'DEVOLUCION' | null;
  idReferencia: number | null;
  idVariante: number;
  sku: string;
  producto: string;
  idUsuario: number;
  correoUsuario: string;
}

export interface FilaConciliacion {
  idVariante: number;
  sku: string;
  existenciaFisica: number;
  sumaKardex: number;
  diferenciaFisica: number;
  existenciaReservada: number;
  sumaReservasActivas: number;
  diferenciaReservada: number;
}

export interface FiltrosExistencias {
  texto?: string;
  idCategoria?: number;
  soloSinDisponibilidad?: boolean;
  activo?: boolean;
  ordenarPor?: 'SKU' | 'Producto' | 'Disponible';
  direccion?: 'ASC' | 'DESC';
  pagina?: number;
  registrosPorPagina?: number;
}

export interface FiltrosKardex {
  idVariante?: number;
  tipoMovimiento?: TipoMovimiento;
  fechaDesde?: string;
  fechaHasta?: string;
  texto?: string;
  pagina?: number;
  registrosPorPagina?: number;
}

export interface FiltrosConciliacion {
  soloDiferencias?: boolean;
  pagina?: number;
  registrosPorPagina?: number;
}

export interface DatosMovimiento {
  idVariante: number;
  cantidad: number;
  motivo: string;
}

export interface ResultadoMovimiento {
  idMovimiento: number;
  existenciaAnterior: number;
  existenciaNueva: number;
}