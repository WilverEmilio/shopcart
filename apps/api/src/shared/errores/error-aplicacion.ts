export class ErrorAplicacion extends Error {
    public readonly codigo: number;
    public readonly estadoHTTP: number;
    public readonly detalles?: {
        campo: string; 
        mensaje: string
    } [];

    constructor (
        mensaje: string,
        codigo: number,
        estadoHTTP: number,
        detalles?: {
            campo: string; 
            mensaje: string
        } []
    ) {
        super (mensaje);

        this.name = 'ErrorAplicacion',
        this.codigo = codigo,
        this.estadoHTTP = estadoHTTP;
        this.detalles = detalles

        Object.setPrototypeOf(this, ErrorAplicacion.prototype);
    }
}