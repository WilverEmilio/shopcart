export interface ErrorApi {
    mensaje: string,
    codigo?: string,
    errores?: Record<string, string[]>;
    estadoHttp?: number;
}