import { formatearMoneda } from '../../../utilidades/formato';
import type { Carrito } from '../../carrito/tipos/carrito';

interface Propiedades {
  carrito: Carrito;
  envio: number | null;
  total: number;
}

export function ResumenPedido({ carrito, envio, total }: Propiedades) {
  return (
    <aside className="tarjeta space-y-4 p-5">
      <h2 className="text-lg font-semibold">Tu pedido</h2>

      <ul className="max-h-72 divide-y divide-gray-100 overflow-y-auto text-sm">
        {carrito.items.map((i) => (
          <li key={i.idVariante} className="flex justify-between gap-3 py-2">
            <span className="min-w-0">
              <span className="text-gray-900">{i.producto}</span>
              {i.atributos && <span className="block text-xs text-gray-600">{i.atributos}</span>}
              <span className="block text-xs text-gray-600">Cantidad: {i.cantidad}</span>
            </span>
            <span className="shrink-0 tabular-nums">{formatearMoneda(i.subtotal)}</span>
          </li>
        ))}
      </ul>

      <dl className="space-y-2 border-t border-gray-200 pt-3 text-sm">
        <div className="flex justify-between">
          <dt className="text-gray-600">Subtotal</dt>
          <dd className="tabular-nums">{formatearMoneda(carrito.subtotal)}</dd>
        </div>
        {carrito.descuento > 0 && (
          <div className="flex justify-between text-green-700">
            <dt>Descuento{carrito.cupon ? ` (${carrito.cupon.codigo})` : ''}</dt>
            <dd className="tabular-nums">−{formatearMoneda(carrito.descuento)}</dd>
          </div>
        )}
        <div className="flex justify-between">
          <dt className="text-gray-600">Envío</dt>
          <dd className={`tabular-nums ${envio === 0 ? 'font-medium text-green-700' : ''} ${envio === null ? 'text-gray-600' : ''}`}>
            {envio === null ? 'Elige un método' : envio === 0 ? 'Gratis' : formatearMoneda(envio)}
          </dd>
        </div>
        <div className="flex items-baseline justify-between border-t border-gray-200 pt-3 font-semibold text-gray-900">
          <dt className="text-base">Total</dt>
          <dd className="text-xl tabular-nums">{formatearMoneda(total)}</dd>
        </div>
        <p className="text-xs text-gray-600">Los precios incluyen IVA.</p>
      </dl>
    </aside>
  );
}
