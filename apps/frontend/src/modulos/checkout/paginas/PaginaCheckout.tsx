import { Navigate, useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { useCheckoutEstado } from '../../../estados/checkoutEstado';
import { CLAVE_CARRITO } from '../../carrito/constantes';
import { useCarrito } from '../../carrito/hooks/useCarrito';
import { PasoPago } from '../componentes/PasoPago';
import { PasoSeleccion } from '../componentes/PasoSeleccion';
import type { PedidoConfirmado } from '../tipos/checkout';

const PASOS = ['Entrega y envío', 'Pago', 'Confirmación'] as const;

function IndicadorPasos({ actual }: { actual: number }) {
  return (
    <ol aria-label="Pasos de la compra" className="mb-8 flex items-center gap-2 text-sm sm:gap-3">
      {PASOS.map((paso, i) => {
        const completado = i < actual;
        const activo = i === actual;
        return (
          <li
            key={paso}
            aria-current={activo ? 'step' : undefined}
            className={`flex min-w-0 items-center gap-2 sm:gap-3 ${i < PASOS.length - 1 ? 'flex-1' : ''}`}
          >
            <span
              className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-semibold ${
                completado
                  ? 'bg-marca-600 text-white'
                  : activo
                    ? 'border-2 border-marca-600 bg-white text-marca-700'
                    : 'border border-gray-300 bg-white text-gray-500'
              }`}
            >
              {completado ? (
                <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" className="h-4 w-4">
                  <path strokeLinecap="round" strokeLinejoin="round" d="m5 12 5 5L20 7" />
                </svg>
              ) : (
                i + 1
              )}
            </span>
            <span className={`whitespace-nowrap ${activo ? 'font-semibold text-gray-900' : 'hidden text-gray-600 sm:inline'}`}>
              {paso}
              {completado && <span className="sr-only"> (completado)</span>}
            </span>
            {i < PASOS.length - 1 && (
              <span aria-hidden="true" className={`h-px min-w-4 flex-1 ${completado ? 'bg-marca-600' : 'bg-gray-300'}`} />
            )}
          </li>
        );
      })}
    </ol>
  );
}

export function PaginaCheckout() {
  const navigate = useNavigate();
  const cliente = useQueryClient();
  const carrito = useCarrito();
  const pago = useCheckoutEstado((e) => e.pago);
  const reiniciar = useCheckoutEstado((e) => e.reiniciar);

  if (carrito.isPending) return <EstadoCarga mensaje="Cargando tu pedido..." />;
  if (carrito.isError) {
    return <EstadoError error={carrito.error} onReintentar={() => void carrito.refetch()} />;
  }

  const datos = carrito.data;
  const pagoActivo = pago?.estado === 'INICIADO' ? pago : null;
  const hayProblemas = datos.items.some((i) => !i.vendible || i.excedeExistencia);


  if (!pagoActivo && (datos.items.length === 0 || hayProblemas)) {
    return <Navigate to="/carrito" replace />;
  }

  const alConfirmado = (pedido: PedidoConfirmado) => {
    navigate('/checkout/confirmacion', { replace: true, state: { pedido } });
    reiniciar();
    void cliente.invalidateQueries({ queryKey: CLAVE_CARRITO });
  };

  return (
    <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 sm:py-8">
      <h1 className="mb-6 text-2xl font-bold tracking-tight sm:text-3xl">Finalizar compra</h1>
      <IndicadorPasos actual={pagoActivo ? 1 : 0} />

      {pagoActivo ? (
        <PasoPago key={pagoActivo.idPago} carrito={datos} pago={pagoActivo} alConfirmado={alConfirmado} />
      ) : (
        <PasoSeleccion carrito={datos} />
      )}
    </main>
  );
}
