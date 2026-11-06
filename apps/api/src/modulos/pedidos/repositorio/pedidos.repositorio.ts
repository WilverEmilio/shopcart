import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import { aFechaUtc } from '../../../shared/utilidades/fechas';
import type { FilaPaginada } from '../../../shared/utilidades/mapeo';
import type { ListarPedidosQuery } from '../esquemas/pedido.esquema';

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

export const listarTodos = async (idActor: number, q: ListarPedidosQuery): Promise<FilaPaginada[]> => {
    const r = await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Pedidos_Listar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Estado', sql.NVarChar(20), q.estado ?? null);
        s.input('IDCliente', sql.Int, q.idCliente ?? null);
        s.input('Texto', sql.NVarChar(100), q.texto ?? null);
        s.input('FechaDesde', sql.Date, aFechaUtc(q.fechaDesde));
        s.input('FechaHasta', sql.Date, aFechaUtc(q.fechaHasta));
        s.input('OrdenarPor', sql.NVarChar(20), q.ordenarPor);
        s.input('Direccion', sql.NVarChar(4), q.direccion);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    });
    return r.recordset;
};

export const avanzarEstado = async (idActor: number, idPedido: number, estado: string, comentario: string | null) => {
    const r = await ejecutarProcedimiento<{ IDPedido: number; Estado: string; Cambio: boolean }>(
        'dbo.SP_Pedidos_AvanzarEstado', s => {
            s.input('IDUsuarioActor', sql.Int, idActor);
            s.input('IDPedido', sql.Int, idPedido);
            s.input('EstadoNuevo', sql.NVarChar(20), estado);
            s.input('Comentario', sql.NVarChar(255), comentario);
        }, { reintentosDeadlock: 2 });
    return r.recordset[0];
};

export const registrarDevolucion = async (
    idActor: number, idPedido: number, motivo: string, devolverTodo: boolean,
    lineas: { idDetallePedido: number; cantidad: number }[]
) => {
    const r = await ejecutarProcedimiento<{ IDDevolucion: number; IDPedido: number; EstadoPedido: string; MontoReembolso: number }>(
        'dbo.SP_Pedidos_RegistrarDevolucion', s => {
            s.input('IDUsuarioActor', sql.Int, idActor);
            s.input('IDPedido', sql.Int, idPedido);
            s.input('Motivo', sql.NVarChar(255), motivo);
            s.input('DevolverTodo', sql.Bit, devolverTodo);
            s.input('Lineas', sql.NVarChar(sql.MAX), devolverTodo ? null : JSON.stringify(lineas));
        }, { reintentosDeadlock: 2 });
    return r.recordset[0];
};

export const listarTransiciones = async () => {
    const r = await ejecutarProcedimiento<{ EstadoOrigen: string; EstadoDestino: string }>('dbo.SP_Pedidos_ListarTransiciones');
    return r.recordset;
};