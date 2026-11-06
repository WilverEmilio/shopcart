export interface DatosCupon {
    descripcion: string | null;
    tipoDescuento: 'PORCENTAJE' | 'MONTO_FIJO';
    valor: number;
    idCategoria: number | null;
    montoMinimo: number;
    fechaInicio: Date;
    fechaFin: Date;
    limiteUsosTotal: number | null;
    limiteUsosPorCliente: number | null;
}