export interface IdentidadCarrito {
    idUsuario: number | null;
    tokenHash: string | null;
}

export interface CarritoResumenBaseDatos {
    IDCarrito: number | null;
    Subtotal: number;
    Descuento: number;
    Total: number;
    BaseImponible: number;
    Iva: number;
    Lineas: number;
    IDCupon: number | null;
    CodigoCupon: string | null;
    CuponRechazo: string | null;
    CuponMensaje: string | null;
}

export interface LineaCarritoBaseDatos {
    IDVariante: number;
    SKU: string;
    IDProducto: number;
    Producto: string;
    Atributos: string | null;
    Precio: number;
    Cantidad: number;
    Subtotal: number;
    Disponible: number;
    Vendible: boolean;
    ExcedeExistencia: boolean;
    ImagenPrincipal: string | null;
}

export interface AjusteFusionBaseDatos {
    IDVariante: number;
    SKU: string;
    Solicitada: number;
    Aplicada: number;
}

export interface ResultadoFusionBaseDatos {
    IDCarrito: number;
    Fusionado: boolean;
}