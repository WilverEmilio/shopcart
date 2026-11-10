import { CLASE_ESTADO, ETIQUETA_ESTADO } from "../constante";
import type { EstadoPedido } from "../tipos/pedido";

export function InsigniaEstado ({estado}: {estado: EstadoPedido}) {
    return (
        <span className={`inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-medium ${CLASE_ESTADO[estado]}`}>
            <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-current opacity-70" />
            {ETIQUETA_ESTADO[estado]}
        </span>
    );
}