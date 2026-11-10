import { Link, Navigate, useLocation } from 'react-router-dom';
import { claseBoton } from '../../../componentes/estilosBoton';
import { formatearMoneda } from '../../../utilidades/formato';
import type { PedidoConfirmado } from '../tipos/checkout';

export function PaginaPedidoConfirmado() {
  const ubicacion = useLocation();
  const pedido = (ubicacion.state as { pedido?: PedidoConfirmado } | null)?.pedido;

  if (!pedido) return <Navigate to="/mis-pedidos" replace />;

  return (
    <main className="mx-auto max-w-lg px-4 py-10 text-center sm:py-16">
      <div className="tarjeta p-6 sm:p-10">
        <span aria-hidden="true" className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-green-100 text-green-700">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="h-8 w-8">
            <path strokeLinecap="round" strokeLinejoin="round" d="m5 12 5 5L20 7" />
          </svg>
        </span>
        <h1 className="mt-5 text-3xl font-bold">¡Pedido confirmado!</h1>
        <p className="mt-2 text-sm text-slate-600">Puedes seguir su estado desde Mis pedidos.</p>

        <dl className="mt-6 divide-y divide-slate-100 rounded-control bg-slate-50 px-4 text-sm">
          {pedido.numeroPedido && (
            <div className="flex justify-between gap-3 py-3">
              <dt className="text-slate-600">Número de pedido</dt>
              <dd className="font-semibold text-slate-900">{pedido.numeroPedido}</dd>
            </div>
          )}
          <div className="flex justify-between gap-3 py-3">
            <dt className="text-slate-600">Total pagado</dt>
            <dd className="precio text-base">{formatearMoneda(pedido.total)}</dd>
          </div>
        </dl>

        <div className="mt-8 flex flex-col gap-2 sm:flex-row sm:justify-center">
          <Link to={pedido.idPedido ? `/mis-pedidos/${pedido.idPedido}` : '/mis-pedidos'} className={claseBoton('primario')}>
            Ver mi pedido
          </Link>
          <Link to="/catalogo" className={claseBoton('secundario')}>
            Seguir comprando
          </Link>
        </div>
      </div>
    </main>
  );
}
