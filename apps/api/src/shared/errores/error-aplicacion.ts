export class ErrorAplicacion extends Error {
    public readonly codigo: number;
    public readonly estadoHTTP: number;

    constructor (
        mensaje: string,
        codigo: number,
        estadoHTTP: number
    ) {
        super (mensaje);

        this.name = 'ErrorAplicacion',
        this.codigo = codigo,
        this.estadoHTTP = estadoHTTP;

        Object.setPrototypeOf(this, ErrorAplicacion.prototype);
    }
}