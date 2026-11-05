import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type {
    IdentidadCarrito, CarritoResumenBaseDatos, LineaCarritoBaseDatos,
    AjusteFusionBaseDatos, ResultadoFusionBaseDatos
} from '../tipos/carrito.tipo';

const REINTENTOS = { reintentosDeadlock: 2 };

const aplicarIdentidad = (solicitud: sql.Request, identidad: IdentidadCarrito): void => {
    solicitud.input('IDUsuario', sql.Int, identidad.idUsuario);
    solicitud.input('TokenHash', sql.Char(64), identidad.tokenHash);
};

export const obtenerCarrito = async (identidad: IdentidadCarrito) => {
    const r = await ejecutarProcedimiento<unknown>(
        'dbo.SP_Carrito_Obtener',
        s => aplicarIdentidad(s, identidad)
    );
    return {
        resumen: r.recordsets[0][0] as CarritoResumenBaseDatos,
        lineas: r.recordsets[1] as LineaCarritoBaseDatos[]
    };
};

export const agregarProducto = async (identidad: IdentidadCarrito, idVariante: number, cantidad: number): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Carrito_AgregarProducto', s => {
        aplicarIdentidad(s, identidad);
        s.input('IDVariante', sql.Int, idVariante);
        s.input('Cantidad', sql.Int, cantidad);
    }, REINTENTOS);
};

export const actualizarCantidad = async (identidad: IdentidadCarrito, idVariante: number, cantidad: number): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Carrito_ActualizarCantidad', s => {
        aplicarIdentidad(s, identidad);
        s.input('IDVariante', sql.Int, idVariante);
        s.input('Cantidad', sql.Int, cantidad);
    }, REINTENTOS);
};

export const eliminarProducto = async (identidad: IdentidadCarrito, idVariante: number): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Carrito_EliminarProducto', s => {
        aplicarIdentidad(s, identidad);
        s.input('IDVariante', sql.Int, idVariante);
    }, REINTENTOS);
};

export const fusionarCarritos = async (idUsuario: number, tokenHash: string) => {
    const r = await ejecutarProcedimiento<unknown>('dbo.SP_Carrito_Fusionar', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('TokenHash', sql.Char(64), tokenHash);
    }, REINTENTOS);
    return {
        resultado: r.recordsets[0][0] as ResultadoFusionBaseDatos,
        ajustes: r.recordsets[1] as AjusteFusionBaseDatos[]
    };
};

export const aplicarCupon = async (idUsuario: number, codigo: string): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Carrito_AplicarCupon', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('Codigo', sql.NVarChar(30), codigo);
    }, REINTENTOS);
};

export const quitarCupon = async (idUsuario: number): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Carrito_QuitarCupon', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
    }, REINTENTOS);
};