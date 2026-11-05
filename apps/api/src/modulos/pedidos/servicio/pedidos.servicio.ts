import * as repositorio from '../repositorio/pedidos.repositorio';
import { mapearFila, mapearFilas } from '../../../shared/utilidades/mapeo';

export const listarMisPedidosServicio = async (idUsuario: number, estado: string | undefined, pagina: number, tamanoPagina: number) => {
    const filas = await repositorio.listarMios(idUsuario, estado, pagina, tamanoPagina);
    return {
        pedidos: mapearFilas(filas.map(({ TotalRegistros, ...resto }) => resto)),
        totalRegistros: filas[0]?.TotalRegistros ?? 0,
        pagina,
        tamanoPagina
    };
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
    return { idPedido: r.IDPedido, estado: r.Estado, cambio: r.Cambio, montoReembolso: r.MontoReembolso };
};