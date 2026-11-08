export interface CuponAplicado {
    idCupon: number;
    codigo: string;
    valido: boolean;
    mensaje: string | null;
}

export interface ItemCarrito {
    idVariante: number;
    sku: string;
    idProducto: string;
    producto: string;
    atributos: string | null;
    precio: number; 
    cantidad: number;
    subtotal: number;
    disponible: number;
    vendible: boolean;
    excedeExistencia: boolean;
    imagen: string | null;
}

export interface Carrito {
    idCarrito: number | null;
    subtotal: number;
    descuento: number;
    total: number;
    baseImponible: number;
    iva: number;
    lineas: number;
    cupon: CuponAplicado | null; 
    items: ItemCarrito[];
}

export interface RespuestaAgregarItem extends Carrito {
    tokenCarrito: string | null;
}

export interface AjusteFusion {
    idVariante: number;
    sku: string;
    solicitada: number;
    aplicada: number;
}

export interface ResultadoFusion {
    fusionado: boolean;
    ajustes: AjusteFusion[];
    carrito: Carrito;
}