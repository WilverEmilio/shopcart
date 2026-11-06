import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type { FilaPaginada } from '../../../shared/utilidades/mapeo';
import type { DatosCupon } from '../tipos/cupon.tipo';
import type { CuponesQuery } from '../esquemas/cupon.esquema';

const REINTENTOS = { reintentosDeadlock: 2 };

const aplicarDatos = (s: sql.Request, d: DatosCupon): void => {
    s.input('Descripcion', sql.NVarChar(255), d.descripcion);
    s.input('TipoDescuento', sql.NVarChar(12), d.tipoDescuento);
    s.input('Valor', sql.Decimal(12, 2), d.valor);
    s.input('IDCategoria', sql.Int, d.idCategoria);
    s.input('MontoMinimo', sql.Decimal(12, 2), d.montoMinimo);
    s.input('FechaInicio', sql.DateTime2(0), d.fechaInicio);
    s.input('FechaFin', sql.DateTime2(0), d.fechaFin);
    s.input('LimiteUsosTotal', sql.Int, d.limiteUsosTotal);
    s.input('LimiteUsosPorCliente', sql.Int, d.limiteUsosPorCliente);
};

export const crearCupon = async (idActor: number, codigo: string, datos: DatosCupon): Promise<number> => {
    const r = await ejecutarProcedimiento<{ IDCupon: number }>('dbo.SP_Cupones_Crear', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Codigo', sql.NVarChar(30), codigo);
        aplicarDatos(s, datos);
    }, REINTENTOS);
    return r.recordset[0].IDCupon;
};

export const actualizarCupon = async (idActor: number, idCupon: number, datos: DatosCupon): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Cupones_Actualizar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDCupon', sql.Int, idCupon);
        aplicarDatos(s, datos);
    }, REINTENTOS);
};

export const cambiarEstadoCupon = async (idActor: number, idCupon: number, activo: boolean) => {
    const r = await ejecutarProcedimiento<{ IDCupon: number; Activo: boolean }>('dbo.SP_Cupones_CambiarEstado', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDCupon', sql.Int, idCupon);
        s.input('Activo', sql.Bit, activo);
    }, REINTENTOS);
    return r.recordset[0];
};

export const eliminarCupon = async (idActor: number, idCupon: number): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Cupones_Eliminar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDCupon', sql.Int, idCupon);
    }, REINTENTOS);
};

export const obtenerCupon = async (idActor: number, idCupon: number): Promise<Record<string, unknown> | undefined> => {
    const r = await ejecutarProcedimiento<Record<string, unknown>>('dbo.SP_Cupones_ObtenerPorID', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDCupon', sql.Int, idCupon);
    });
    return r.recordset[0];
};

export const listarCupones = async (idActor: number, q: CuponesQuery): Promise<FilaPaginada[]> =>
    (await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Cupones_Listar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Busqueda', sql.NVarChar(100), q.busqueda ?? null);
        s.input('Estado', sql.NVarChar(12), q.estado ?? null);
        s.input('IDCategoria', sql.Int, q.idCategoria ?? null);
        s.input('OrdenarPor', sql.NVarChar(20), q.ordenarPor);
        s.input('Direccion', sql.NVarChar(4), q.direccion);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;