import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';

type Fila = Record<string, unknown>;

export const listarMios = async (idUsuario: number, estado: string | undefined, pagina: number, tamanoPagina: number) => {
    const r = await ejecutarProcedimiento<Fila & { TotalRegistros: number }>('dbo.SP_Pedidos_ListarMios', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('Estado', sql.NVarChar(20), estado ?? null);
        s.input('Pagina', sql.Int, pagina);
        s.input('TamanoPagina', sql.Int, tamanoPagina);
    });
    return r.recordset;
};

export const obtenerDetalle = async (idUsuarioActor: number, idPedido: number) => {
    const r = await ejecutarProcedimiento<unknown>('dbo.SP_Pedidos_ObtenerDetalle', s => {
        s.input('IDUsuarioActor', sql.Int, idUsuarioActor);
        s.input('IDPedido', sql.Int, idPedido);
    });
    return {
        pedido: r.recordsets[0][0] as Fila,
        lineas: r.recordsets[1] as Fila[],
        historial: r.recordsets[2] as Fila[],
        devoluciones: r.recordsets[3] as Fila[],
        detalleDevoluciones: r.recordsets[4] as Fila[]
    };
};

export const cancelarPedido = async (idUsuarioActor: number, idPedido: number, motivo: string) => {
    const r = await ejecutarProcedimiento<{ IDPedido: number; Estado: string; Cambio: boolean; MontoReembolso: number }>(
        'dbo.SP_Pedidos_Cancelar', s => {
            s.input('IDUsuarioActor', sql.Int, idUsuarioActor);
            s.input('IDPedido', sql.Int, idPedido);
            s.input('Motivo', sql.NVarChar(255), motivo);
        }, { reintentosDeadlock: 2 });
    return r.recordset[0];
};