export interface DatosIniciarPago {
    idDireccion: number;
    idMetodoEnvio: number;
    totalEsperado?: number;
}

export interface PagoBaseDatos {
    IDPago: number;
    Estado: 'INICIADO' | 'APROBADO' | 'RECHAZADO' | 'EXPIRADO' | 'ANULADO';
    Total: number;
    IDPedido: number | null;
    NumeroPedido: string | null;
    IDReserva: number | null;
    FechaVencimiento: Date | null;
    Motivo: string | null;
}

export interface IniciarPagoBaseDatos {
    IDPago: number;
    Estado: string;
    Nuevo: boolean;
    IDPedido: number | null;
    IDReserva: number | null;
    FechaVencimiento: Date | null;
    Total: number;
}

export interface CrearPedidoBaseDatos {
    IDPago: number;
    Estado: string;
    Nuevo: boolean;
    IDPedido: number | null;
    NumeroPedido: string | null;
    Total: number;
    Motivo: string | null;
}

export interface MetodoEnvioBaseDatos {
    IDMetodoEnvio: number;
    Nombre: string;
    Descripcion: string | null;
    Costo: number;
    DiasEstimados: number;
}