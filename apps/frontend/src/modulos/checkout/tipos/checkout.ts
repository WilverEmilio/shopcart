export interface MetodoEnvio {
    idMetodoEnvio: number;
    nombre: string;
    descripcion: string | null;
    costo: number;
    diasEstaimados: number;
}

export type EstadoPago = 'INICIADO' | 'APROBADO' | 'RECHAZADO' | 'EXPIRADO' | 'ANULADO';

export interface PagoIniciado {
    idPago: number;
    estado: EstadoPago;
    idPedido: number | null;
    idReserva: number | null;
    fechaVencimiento: string | null;
    total: number;
}

export interface PedidoConfirmado {
    idPedido: number | null;
    numeroPedido: string | null;
    total: number;
}