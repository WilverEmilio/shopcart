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
          className={`rounded-lg p-4 ${expirada ? 'bg-red-50 text-red-800' : restante < 120_000 ? 'bg-amber-50 text-amber-800' : 'bg-indigo-50 text-indigo-800'}`}
        >
          {expirada ? (
            <p className="font-medium">
              La reserva venció y tus productos fueron liberados. Vuelve a empezar para reservarlos de nuevo.
            </p>
          ) : (
            <>
              <p className="text-sm">Reservamos tus productos. Completa el pago en:</p>
              <p className="text-3xl font-bold tabular-nums">{formatearTemporizador(restante)}</p>
            </>
          )}
        </div>

        <section aria-labelledby="titulo-pago" className="space-y-3">
          <h2 id="titulo-pago" className="text-lg font-semibold">
            3. Pago
          </h2>
          <p className="text-sm text-gray-500">
            Entorno de pruebas: elige el resultado que quieres simular. Los datos de tarjeta nunca pasan por nuestro servidor.
          </p>

          {ESCENARIOS.map((e) => (
            <label
              key={e.token}
              className={`flex cursor-pointer gap-3 rounded-lg border p-4 ${
                tokenPago === e.token ? 'border-indigo-600 bg-indigo-50' : 'border-gray-200 bg-white'
              }`}
            >
              <input
                type="radio"
                name="escenario"
                className="mt-1"
                checked={tokenPago === e.token}
                disabled={expirada || cerrado || confirmar.isPending}
                onChange={() => setTokenPago(e.token)}
              />
              <span className="text-sm">
                <span className="block font-medium">{e.etiqueta}</span>
                <span className="block text-gray-600">{e.detalle}</span>
              </span>
            </label>
          ))}
        </section>

        {error && (
          <div role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
            <p>{error.mensaje}</p>
            {reintentable && (
              <p className="mt-1">Puedes reintentar: se usa la misma solicitud, así que no se cobra dos veces.</p>
            )}
          </div>
        )}

        <div className="flex flex-wrap items-center gap-3">
          {expirada || cerrado ? (
            <Boton onClick={reiniciar}>Volver a empezar</Boton>
          ) : (
            <>
              <Boton onClick={pagar} cargando={confirmar.isPending}>
                {reintentable ? 'Reintentar pago' : `Pagar ${formatearMoneda(pago.total)}`}
              </Boton>
              <button
                type="button"
                onClick={reiniciar}
                disabled={confirmar.isPending}
                className="text-sm text-gray-600 underline disabled:opacity-50"
              >
                Cambiar dirección o envío
              </button>
            </>
          )}
        </div>
      </div>

      <ResumenPedido carrito={carrito} envio={envio} total={pago.total} />
    </div>
  );
}