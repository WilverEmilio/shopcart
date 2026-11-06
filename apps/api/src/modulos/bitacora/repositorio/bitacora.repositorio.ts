import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import { aFechaUtc, aFinDeDiaUtc } from '../../../shared/utilidades/fechas';
import type { FilaPaginada } from '../../../shared/utilidades/mapeo';
import type { BitacoraQuery } from '../esquemas/bitacora.esquema';

export const listarBitacora = async (idActor: number, q: BitacoraQuery): Promise<FilaPaginada[]> =>
    (await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Bitacora_Listar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Modulo', sql.NVarChar(50), q.modulo ?? null);
        s.input('IDUsuario', sql.Int, q.idUsuario ?? null);
        s.input('FechaDesde', sql.DateTime2(0), aFechaUtc(q.fechaDesde));
        s.input('FechaHasta', sql.DateTime2(0), aFinDeDiaUtc(q.fechaHasta));
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;