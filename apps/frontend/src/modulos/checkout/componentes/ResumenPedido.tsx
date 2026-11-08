import { formatearMoneda } from '../../../utilidades/formato';
import type { Carrito } from '../../carrito/tipos/carrito';

interface Propiedades {
  carrito: Carrito;
  envio: number | null;
  total: number;
}

export function ResumenPedido({ carrito, envio, total }: Propiedades) {
  return (
    <aside className="space-y-4 rounded-lg border border-gray-200 bg-white p-5 lg:self-start">
      <h2 className="text-lg font-semibold">Tu pedido</h2>

      <ul className="divide-y divide-gray-100 text-sm">
        {carrito.items.map((i) => (
          <li key={i.idVariante} className="flex justify-between gap-3 py-2">
            <span>
              {i.producto}
              {i.atributos && <span className="text-gray-500"> ({i.atributos})</span>} × {i.cantidad}
            </span>
            <span className="shrink-0">{formatearMoneda(i.subtotal)}</span>
          </li>
        ))}
      </ul>

      <dl className="space-y-2 border-t border-gray-200 pt-3 text-sm">
        <div className="flex justify-between">
          <dt className="text-gray-600">Subtotal</dt>
          <dd>{formatearMoneda(carrito.subtotal)}</dd>
        </div>
        {carrito.descuento > 0 && (
          <div className="flex justify-between text-green-700">
            <dt>Descuento{carrito.cupon ? ` (${carrito.cupon.codigo})` : ''}</dt>
            <dd>−{formatearMoneda(carrito.descuento)}</dd>
          </div>
        )}
        <div className="flex justify-between">
          <dt className="text-gray-600">Envío</dt>
          <dd>{envio === null ? 'Elige un método' : envio === 0 ? 'Gratis' : formatearMoneda(envio)}</dd>
        </div>
        <div className="flex justify-between border-t border-gray-200 pt-2 text-base font-semibold">
          <dt>Total</dt>
          <dd>{formatearMoneda(total)}</dd>
        </div>
        <p className="text-xs text-gray-500">Los precios incluyen IVA.</p>
      </dl>
    </aside>
  );
}