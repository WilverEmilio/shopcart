import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';

interface Atributo { atributo: string; valor: string }
interface Imagen { url: string; orden?: number; esPrincipal?: boolean }

const REINTENTOS = { reintentosDeadlock: 2 };

export const crearVariante = async (idActor: number, idProducto: number, sku: string, precio: number, atributos: Atributo[]) => {
    const r = await ejecutarProcedimiento<{ IDVariante: number }>('dbo.SP_Variantes_Crear', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDProducto', sql.Int, idProducto);
        s.input('SKU', sql.NVarChar(50), sku);
        s.input('Precio', sql.Decimal(12, 2), precio);
        s.input('Atributos', sql.NVarChar(sql.MAX), JSON.stringify(atributos));
    }, REINTENTOS);
    return r.recordset[0];
};

export const actualizarVariante = async (idActor: number, idVariante: number, sku: string, atributos?: Atributo[]) => {
    const r = await ejecutarProcedimiento<{ IDVariante: number }>('dbo.SP_Variantes_Actualizar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDVariante', sql.Int, idVariante);
        s.input('SKU', sql.NVarChar(50), sku);
        s.input('Atributos', sql.NVarChar(sql.MAX), atributos ? JSON.stringify(atributos) : null);
    }, REINTENTOS);
    return r.recordset[0];
};

export const cambiarEstadoVariante = async (idActor: number, idVariante: number, activo: boolean) => {
    const r = await ejecutarProcedimiento<{ IDVariante: number; Activo: boolean }>('dbo.SP_Variantes_CambiarEstado', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDVariante', sql.Int, idVariante);
        s.input('Activo', sql.Bit, activo);
    }, REINTENTOS);
    return r.recordset[0];
};

export const cambiarPrecioVariante = async (idActor: number, idVariante: number, precio: number) => {
    const r = await ejecutarProcedimiento<{ IDVariante: number; Precio: number }>('dbo.SP_Variantes_CambiarPrecio', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDVariante', sql.Int, idVariante);
        s.input('PrecioNuevo', sql.Decimal(12, 2), precio);
    }, REINTENTOS);
    return r.recordset[0];
};

export const eliminarVariante = async (idActor: number, idVariante: number) => {
    const r = await ejecutarProcedimiento<{ IDVariante: number; Resultado: string }>('dbo.SP_Variantes_Eliminar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDVariante', sql.Int, idVariante);
    }, REINTENTOS);
    return r.recordset[0];
};

export const reemplazarImagenes = async (idActor: number, idProducto: number, imagenes: Imagen[]) => {
    const r = await ejecutarProcedimiento<{ IDProducto: number }>('dbo.SP_Productos_ReemplazarImagenes', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDProducto', sql.Int, idProducto);
        s.input('Imagenes', sql.NVarChar(sql.MAX), JSON.stringify(imagenes));
    }, REINTENTOS);
    return r.recordset[0];
};