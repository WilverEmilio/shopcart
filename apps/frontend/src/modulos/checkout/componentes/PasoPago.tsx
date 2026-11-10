import { useState } from 'react';
import { Boton } from '../../../componentes/Boton';
import { useCheckoutEstado } from '../../../estados/checkoutEstado';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda, formatearTemporizador } from '../../../utilidades/formato';
import type { Carrito } from '../../carrito/tipos/carrito';
import { useConfirmarPago } from '../hooks/useCheckout';
import { useCuentaRegresiva } from '../hooks/useCuentaRegresiva';
import type { PagoIniciado, PedidoConfirmado } from '../tipos/checkout';
import { ResumenPedido } from './ResumenPedido';

const ESCENARIOS = [
  { token: 'tok_aprobado', etiqueta: 'Tarjeta aprobada', detalle: 'El cobro se aprueba y se crea el pedido.' },
  { token: 'tok_rechazado', etiqueta: 'Tarjeta rechazada', detalle: 'El banco rechaza el cobro y se libera la reserva.' },
  { token: 'tok_error_red', etiqueta: 'Falla de red de la pasarela', detalle: 'El primer intento falla; al reintentar con la misma solicitud se aprueba.' },
] as const;

interface Propiedades {
  carrito: Carrito;
  pago: PagoIniciado;
  alConfirmado: (pedido: PedidoConfirmado) => void;
}

export function PasoPago({ carrito, pago, alConfirmado }: Propiedades) {
  const reiniciar = useCheckoutEstado((e) => e.reiniciar);
  const confirmar = useConfirmarPago();
  const restante = useCuentaRegresiva(pago.fechaVencimiento);
  const [tokenPago, setTokenPago] = useState<string>(ESCENARIOS[0].token);

  const expirada = restante <= 0;
  const error = confirmar.isError ? normalizarError(confirmar.error) : null;
  const reintentable = error?.estadoHttp === 504; // falla de red: misma solicitud
  const cerrado = error !== null && !reintentable && (error.estadoHttp === 402 || error.estadoHttp === 409);
  const envio = Math.round((pago.total - carrito.total) * 100) / 100;

  const pagar = () => confirmar.mutate(tokenPago, { onSuccess: alConfirmado });

  return (
    <div className="grid gap-8 lg:grid-cols-[1fr_22rem]">
      <div className="space-y-6">
        <div
          role="timer"
          aria-label="Tiempo restante de la reserva"
          className={`flex items-center gap-4 rounded-tarjeta border p-4 sm:p-5 ${
            expirada
              ? 'border-red-200 bg-red-50 text-red-800'
              : restante < 120_000
                ? 'border-amber-300 bg-amber-50 text-amber-900'
                : 'border-marca-100 bg-marca-50 text-marca-800'
          }`}
        >
          <span aria-hidden="true" className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-white/70">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-6 w-6">
              <circle cx="12" cy="13" r="8" />
              <path strokeLinecap="round" d="M12 9v4l2 2M9 2h6" />
            </svg>
          </span>
          {expirada ? (
            <p className="font-medium">
              La reserva venció y tus productos fueron liberados. Vuelve a empezar para reservarlos de nuevo.
            </p>
          ) : (
            <div className="flex flex-1 flex-wrap items-center justify-between gap-x-4 gap-y-1">
              <p className="text-sm">Reservamos tus productos. Completa el pago en:</p>
              <p className="text-3xl font-bold tabular-nums">{formatearTemporizador(restante)}</p>
            </div>
          )}
        </div>

        <section aria-labelledby="titulo-pago" className="space-y-3">
          <h2 id="titulo-pago" className="text-lg font-semibold">
            Método de pago
          </h2>
          <p className="text-sm text-gray-600">
            Entorno de pruebas: elige el resultado que quieres simular. Los datos de tarjeta nunca pasan por nuestro servidor.
          </p>

          {ESCENARIOS.map((e) => (
            <label key={e.token} className="opcion-seleccionable">
              <input
                type="radio"
                name="escenario"
                className="mt-0.5 h-4 w-4 shrink-0"
                checked={tokenPago === e.token}
                disabled={expirada || cerrado || confirmar.isPending}
                onChange={() => setTokenPago(e.token)}
              />
              <span className="text-sm">
                <span className="block font-medium text-gray-900">{e.etiqueta}</span>
                <span className="block text-gray-600">{e.detalle}</span>
              </span>
            </label>
          ))}
        </section>

        {error && (
          <div role="alert" className="flex gap-3 rounded-tarjeta border border-red-200 bg-red-50 p-4 text-sm text-red-700">
            <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="mt-0.5 h-5 w-5 shrink-0">
              <circle cx="12" cy="12" r="9" />
              <path strokeLinecap="round" d="M12 8v4m0 4h.01" />
            </svg>
            <div>
              <p className="font-medium">{error.mensaje}</p>
              {reintentable && (
                <p className="mt-1">Puedes reintentar: se usa la misma solicitud, así que no se cobra dos veces.</p>
              )}
            </div>
          </div>
        )}

        <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
          {expirada || cerrado ? (
            <Boton onClick={reiniciar} className="w-full sm:w-auto">
              Volver a empezar
            </Boton>
          ) : (
            <>
              <Boton onClick={pagar} cargando={confirmar.isPending} className="w-full sm:w-auto sm:min-w-48">
                {reintentable ? 'Reintentar pago' : `Pagar ${formatearMoneda(pago.total)}`}
              </Boton>
              <button
                type="button"
                onClick={reiniciar}
                disabled={confirmar.isPending}
                className="min-h-11 text-sm font-medium text-gray-700 underline underline-offset-2 hover:text-gray-900 disabled:opacity-50"
              >
                Cambiar dirección o envío
              </button>
            </>
          )}
        </div>
      </div>

      <div className="lg:sticky lg:top-20 lg:self-start">
        <ResumenPedido carrito={carrito} envio={envio} total={pago.total} />
      </div>
    </div>
  );
}
