import { Link, Navigate, useLocation } from 'react-router-dom';
import { formatearMoneda } from '../../../utilidades/formato';
import type { PedidoConfirmado } from '../tipos/checkout';

export function PaginaPedidoConfirmado() {
  const ubicacion = useLocation();
  const pedido = (ubicacion.state as { pedido?: PedidoConfirmado } | null)?.pedido;

  if (!pedido) return <Navigate to="/mis-pedidos" replace />;

  return (
    <main className="mx-auto max-w-lg p-6 text-center">
      <div className="rounded-lg border border-gray-200 bg-white p-8">
        <p className="text-4xl">✅</p>
        <h1 className="mt-3 text-2xl font-semibold">¡Pedido confirmado!</h1>

        {pedido.numeroPedido && (
          <p className="mt-2 text-gray-600">
            Número de pedido: <strong>{pedido.numeroPedido}</strong>
          </p>
        )}
        <p className="mt-1 text-gray-600">
          Total pagado: <strong>{formatearMoneda(pedido.total)}</strong>
        </p>

        <div className="mt-6 flex flex-col gap-2 sm:flex-row sm:justify-center">
          <Link to="/mis-pedidos" className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">
            Ver mis pedidos
          </Link>
          <Link to="/catalogo" className="rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100">
            Seguir comprando
          </Link>
        </div>
      </div>
    </main>
  );
}