import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import { aFechaUtc, aFinDeDiaUtc } from '../../../shared/utilidades/fechas';
import type { FilaPaginada } from '../../../shared/utilidades/mapeo';
import type { ExistenciasQuery, KardexQuery, ConciliacionQuery } from '../esquemas/inventario.esquema';

interface ResultadoMovimiento { IDMovimiento: number; ExistenciaAnterior: number; ExistenciaNueva: number }

export const listarExistencias = async (idActor: number, q: ExistenciasQuery): Promise<FilaPaginada[]> =>
    (await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Inventario_ListarExistencias', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Texto', sql.NVarChar(100), q.texto ?? null);
        s.input('IDCategoria', sql.Int, q.idCategoria ?? null);
        s.input('SoloSinDisponibilidad', sql.Bit, q.soloSinDisponibilidad);
        s.input('Activo', sql.Bit, q.activo ?? null);
        s.input('OrdenarPor', sql.NVarChar(20), q.ordenarPor);
        s.input('Direccion', sql.NVarChar(4), q.direccion);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;

export const listarKardex = async (idActor: number, q: KardexQuery): Promise<FilaPaginada[]> =>
    (await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Inventario_ListarKardex', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDVariante', sql.Int, q.idVariante ?? null);
        s.input('TipoMovimiento', sql.NVarChar(20), q.tipoMovimiento ?? null);
        s.input('FechaDesde', sql.DateTime2(0), aFechaUtc(q.fechaDesde));
        s.input('FechaHasta', sql.DateTime2(0), aFinDeDiaUtc(q.fechaHasta));
        s.input('Texto', sql.NVarChar(100), q.texto ?? null);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;

export const obtenerConciliacion = async (idActor: number, q: ConciliacionQuery): Promise<FilaPaginada[]> =>
    (await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Inventario_ObtenerConciliacion', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('SoloDiferencias', sql.Bit, q.soloDiferencias);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;

const movimiento = (procedimiento: string) =>
    async (idActor: number, idVariante: number, cantidad: number, motivo: string): Promise<ResultadoMovimiento> => {
        const r = await ejecutarProcedimiento<ResultadoMovimiento>(procedimiento, s => {
            s.input('IDUsuarioActor', sql.Int, idActor);
            s.input('IDVariante', sql.Int, idVariante);
            s.input('Cantidad', sql.Int, cantidad);
            s.input('Motivo', sql.NVarChar(255), motivo);
        }, { reintentosDeadlock: 2 });
        return r.recordset[0];
    };

export const registrarEntrada = movimiento('dbo.SP_Inventario_RegistrarEntrada');
export const registrarAjuste = movimiento('dbo.SP_Inventario_RegistrarAjuste');