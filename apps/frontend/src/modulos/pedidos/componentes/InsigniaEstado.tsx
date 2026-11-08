import { CLASE_ESTADO, ETIQUETA_ESTADO } from "../constante";
import type { EstadoPedido } from "../tipos/pedido";

export function InsigniaEstado ({estado}: {estado: EstadoPedido}) {
    return (
        <span className={`inline-block whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-medium ${CLASE_ESTADO[estado]}`}>
            {ETIQUETA_ESTADO[estado]}
        </span>
    );
}