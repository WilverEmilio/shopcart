import * as repositorio from '../repositorio/pedidos.repositorio';
import { mapearFila, mapearFilas } from '../../../shared/utilidades/mapeo';
import { FilaPaginada, paginasFilas } from '../../../shared/utilidades/mapeo';
import { ListarPedidosQuery } from '../esquemas/pedido.esquema';

export const listarMisPedidosServicio = async (idUsuario: number, estado: string | undefined, pagina: number, tamanoPagina: number) => {
    const filas = await repositorio.listarMios(idUsuario, estado, pagina, tamanoPagina);
    return paginasFilas (
        filas as FilaPaginada[], 
        pagina, 
        tamanoPagina
    )
};

export const obtenerDetallePedidoServicio = async (idUsuarioActor: number, idPedido: number) => {
    const d = await repositorio.obtenerDetalle(idUsuarioActor, idPedido);
    return {
        ...mapearFila(d.pedido),
        items: mapearFilas(d.lineas),
        historial: mapearFilas(d.historial),
        devoluciones: mapearFilas(d.devoluciones),
        detalleDevoluciones: mapearFilas(d.detalleDevoluciones)
    };
};

export const cancelarPedidoServicio = async (idUsuarioActor: number, idPedido: number, motivo: string) => {
    const r = await repositorio.cancelarPedido(idUsuarioActor, idPedido, motivo);
    return { idPedido: r.IDPedido, 
        estado: r.Estado, 
        cambio: r.Cambio, 
        montoReembolso: r.MontoReembolso
     };
};

export const listarPedidosServicio = async (
    idActor: number, 
    q: ListarPedidosQuery
) =>
    paginasFilas(await repositorio.listarTodos(idActor, q), 
    q.pagina, 
    q.registrosPorPagina
);

export const avanzarEstadoServicio = async (
    idActor: number, 
    idPedido: number, 
    estado: string, 
    comentario: string | null
) => {
    const r = await repositorio.avanzarEstado(
        idActor, 
        idPedido, 
        estado, 
        comentario
    );
    return { idPedido: r.IDPedido,
         estado: r.Estado, 
         cambio: r.Cambio 
        };
};

export const registrarDevolucionServicio = async (
    idActor: number, 
    idPedido: number,
    datos: { 
        motivo: string; 
        devolverTodo: boolean; 
        lineas: { 
            idDetallePedido: number; 
            cantidad: number 
        }[]
    }
) => {
    const r = await repositorio.registrarDevolucion(
        idActor, 
        idPedido, 
        datos.motivo, 
        datos.devolverTodo, 
        datos.lineas
    );
    return { 
        idDevolucion: r.IDDevolucion,
         idPedido: r.IDPedido, 
         estadoPedido: r.EstadoPedido, 
         montoReembolso: r.MontoReembolso
        };
};

export const listarTransicionesServicio = async () =>
    (await repositorio.listarTransiciones()).map(
        t => ({ 
            origen: t.EstadoOrigen,
            destino: t.EstadoDestino
         }));