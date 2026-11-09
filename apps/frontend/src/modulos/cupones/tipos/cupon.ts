export type EstadoCupon = 'INACTIVO' | 'PROGRAMADO' | 'VENCIDO' | 'AGOTADO' | 'VIGENTE';
export type TipoDescuento = 'PORCENTAJE' | 'MONTO_FIJO';

export interface Cupon {
  idCupon: number;
  codigo: string;
  descripcion: string | null;
  tipoDescuento: TipoDescuento;
  valor: number;
  idCategoria: number | null;
  categoria: string | null;
  montoMinimo: number;
  fechaInicio: string;
  fechaFin: string;
  limiteUsosTotal: number | null;
  limiteUsosPorCliente: number | null;
  usosActuales: number;
  activo: boolean;
  fechaCreacion: string;
  estado: EstadoCupon;
}

export interface FiltrosCupones {
  busqueda?: string;
  estado?: EstadoCupon;
  idCategoria?: number;
  ordenarPor?: 'Codigo' | 'FechaFin' | 'UsosActuales' | 'FechaCreacion';
  direccion?: 'ASC' | 'DESC';
  pagina?: number;
  registrosPorPagina?: number;
}

export interface DatosCupon {
  descripcion: string | null;
  tipoDescuento: TipoDescuento;
  valor: number;
  idCategoria: number | null;
  montoMinimo: number;
  fechaInicio: string;
  fechaFin: string;
  limiteUsosTotal: number | null;
  limiteUsosPorCliente: number | null;
}

export interface DatosCuponNuevo extends DatosCupon {
  codigo: string;
}

export interface CuponFormulario {
  codigo: string;
  descripcion: string;
  tipoDescuento: TipoDescuento;
  valor: string;
  idCategoria: string;
  montoMinimo: string;
  fechaInicio: string;
  fechaFin: string;
  limiteUsosTotal: string;
  limiteUsosPorCliente: string;
}