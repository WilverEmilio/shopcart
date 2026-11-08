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
    <main className="mx-auto max-w-7xl p-6">
      <h1 className="mb-6 text-2xl font-semibold">Finalizar compra</h1>

      {pagoActivo ? (
        <PasoPago key={pagoActivo.idPago} carrito={datos} pago={pagoActivo} alConfirmado={alConfirmado} />
      ) : (
        <PasoSeleccion carrito={datos} />
      )}
    </main>
  );
}