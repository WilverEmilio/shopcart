export interface DetalleErrorApi{
    campo: string;
    mensaje: string;
}

export interface ErrorApi {
    mensaje: string;
    codigo?: number;
    detalles?: DetalleErrorApi[];
    estadoHttp?: number;
}