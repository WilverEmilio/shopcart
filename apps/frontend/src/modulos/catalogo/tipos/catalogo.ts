export type OrderCatalogo = "Nombre" | 'Precio' | 'FechaCreacion'; 
export type DireccionCatalogo = 'ASC' | 'DESC';

export interface FiltrosCatalogo {
    texto?: string;
    idCategoria?: number;
    precioMinimo?: number;
    precioMaximo?: number;
    soloDisponibles?: boolean;
    activo?: boolean;
    ordenadoPor?: OrderCatalogo;
    direccion?: DireccionCatalogo;
    pagina?: number;
    registroPorPagina?: number;
}

export interface CateggoriaPublica {
    idCategoria: number;
    nombre: string;
    descripcion: string | null;
}

export interface RespuestaCatalogo <T> {
    mensaje: string,
    datos: T;
}