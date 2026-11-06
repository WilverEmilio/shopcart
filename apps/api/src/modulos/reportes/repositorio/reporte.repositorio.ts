import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import { aFechaUtc } from '../../../shared/utilidades/fechas';
import type { FilaPaginada } from '../../../shared/utilidades/mapeo';
import type { RangoQuery, VentasPeriodoQuery, TopProductosQuery, AbandonadosQuery } from '../esquemas/reporte.esquema';

type Fila = Record<string, unknown>;

const conRango = (s: sql.Request, idActor: number, q: RangoQuery): void => {
    s.input('IDUsuarioActor', sql.Int, idActor);
    s.input('FechaDesde', sql.Date, aFechaUtc(q.fechaDesde));
    s.input('FechaHasta', sql.Date, aFechaUtc(q.fechaHasta));
};

export const obtenerResumen = async (idActor: number, q: RangoQuery): Promise<Fila> =>
    (await ejecutarProcedimiento<Fila>('dbo.SP_Reportes_ResumenDashboard', s => conRango(s, idActor, q))).recordset[0];

export const ventasPorPeriodo = async (idActor: number, q: VentasPeriodoQuery): Promise<Fila[]> =>
    (await ejecutarProcedimiento<Fila>('dbo.SP_Reportes_VentasPorPeriodo', s => {
        conRango(s, idActor, q);
        s.input('Agrupacion', sql.NVarChar(10), q.agrupacion);
    })).recordset;

export const ventasPorCategoria = async (idActor: number, q: RangoQuery): Promise<Fila[]> =>
    (await ejecutarProcedimiento<Fila>('dbo.SP_Reportes_VentasPorCategoria', s => conRango(s, idActor, q))).recordset;

export const topProductos = async (idActor: number, q: TopProductosQuery): Promise<Fila[]> =>
    (await ejecutarProcedimiento<Fila>('dbo.SP_Reportes_TopProductos', s => {
        conRango(s, idActor, q);
        s.input('Top', sql.Int, q.top);
        s.input('OrdenarPor', sql.NVarChar(10), q.ordenarPor);
    })).recordset;

export const carritosAbandonados = async (idActor: number, q: AbandonadosQuery): Promise<(FilaPaginada & { ValorTotal: number })[]> =>
    (await ejecutarProcedimiento<FilaPaginada & { ValorTotal: number }>('dbo.SP_Reportes_CarritosAbandonados', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('OrdenarPor', sql.NVarChar(20), q.ordenarPor);
        s.input('Direccion', sql.NVarChar(4), q.direccion);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;