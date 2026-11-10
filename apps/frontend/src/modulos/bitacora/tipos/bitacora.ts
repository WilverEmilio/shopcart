export const MODULOS_BITACORA = [
    'Usuario',
    'Catalogo',
    'Productos',
    'Precios',
    'Inventario',
    'Cupones',
    'Pedidos',
    'Configuracion'
] as const;

export type ModuloBitacora = (typeof MODULOS_BITACORA)[number];

export interface RegistroBitacora {
    idBitacora: number | string;
    fecha: string;
    modulo: string;
    entidad: string;
    idEntidad: number | string | null; 
    accios: string;
    valorAnterior: unknown;
    valorNuevo: unknown;
    idUsuario: number | null;
    correoUsuario: string | null;
}

export interface FiltrosBitacora {
    modulo?: ModuloBitacora,
    idUsuario?: number;
    fechaDesde?: string;
    fechaHasta?: string;
    pagina?: number;
    registrosPorPagina?: number;
}
