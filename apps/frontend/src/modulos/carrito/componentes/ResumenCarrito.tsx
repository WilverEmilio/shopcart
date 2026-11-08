import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda } from '../../../utilidades/formato';
import type { AccionesCarrito } from '../hooks/useCarrito';
import type { Carrito } from '../tipos/carrito';

interface Propiedades {
  carrito: Carrito;
  acciones: AccionesCarrito;
  esCliente: boolean;
}

const claseEnlaceBoton =
  'block w-full rounded-md bg-indigo-600 px-4 py-2 text-center text-sm font-medium text-white hover:bg-indigo-700';

export function ResumenCarrito({ carrito, acciones, esCliente }: Propiedades) {
  const [codigo, setCodigo] = useState('');

  const hayProblemas = carrito.items.some((i) => !i.vendible || i.excedeExistencia);
  const vacio = carrito.items.length === 0;

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    const limpio = codigo.trim();
    if (!limpio) return;

    acciones.reiniciarErrores();
    acciones.aplicarCupon.mutate(limpio, { onSuccess: () => setCodigo('') });
  };

  return (
    <aside className="space-y-4 rounded-lg border border-gray-200 bg-white p-5 lg:self-start">
      <h2 className="text-lg font-semibold">Resumen</h2>

      <dl className="space-y-2 text-sm">
        <div className="flex justify-between">
          <dt className="text-gray-600">Subtotal</dt>
          <dd>{formatearMoneda(carrito.subtotal)}</dd>
        </div>

        {carrito.descuento > 0 && (
          <div className="flex justify-between text-green-700">
            <dt>Descuento</dt>
            <dd>−{formatearMoneda(carrito.descuento)}</dd>
          </div>
        )}

        <div className="flex justify-between border-t border-gray-200 pt-2 text-base font-semibold">
          <dt>Total</dt>
          <dd>{formatearMoneda(carrito.total)}</dd>
        </div>
        <p className="text-xs text-gray-500">Incluye IVA de {formatearMoneda(carrito.iva)}. El envío se calcula al pagar.</p>
      </dl>

      {esCliente ? (
        <div className="border-t border-gray-200 pt-4">
          {carrito.cupon ? (
            <div className="space-y-1 text-sm">
              <div className="flex items-center justify-between">
                <span>
                  Cupón <strong>{carrito.cupon.codigo}</strong>
                </span>
                <button
                  type="button"
                  disabled={acciones.ocupado}
                  onClick={() => {
                    acciones.reiniciarErrores();
                    acciones.quitarCupon.mutate();
                  }}
                  className="text-red-600 hover:underline disabled:opacity-50"
                >
                  Quitar
                </button>
              </div>
              {!carrito.cupon.valido && carrito.cupon.mensaje && (
                <p role="alert" className="text-amber-600">
                  {carrito.cupon.mensaje}
                </p>
              )}
            </div>
          ) : (
            <form onSubmit={aplicar} noValidate className="flex items-end gap-2">
              <div className="flex-1">
                <CampoFormulario
                  etiqueta="Cupón de descuento"
                  value={codigo}
                  maxLength={30}
                  autoComplete="off"
                  className="uppercase"
                  onChange={(e) => setCodigo(e.target.value)}
                />
              </div>
              <Boton type="submit" variante="secundario" cargando={acciones.aplicarCupon.isPending} disabled={acciones.ocupado}>
                Aplicar
              </Boton>
            </form>
          )}

          {acciones.aplicarCupon.isError && (
            <p role="alert" className="mt-2 text-sm text-red-600">
              {normalizarError(acciones.aplicarCupon.error).mensaje}
            </p>
          )}
        </div>
      ) : (
        <p className="border-t border-gray-200 pt-4 text-sm text-gray-500">
          Inicia sesión para usar un cupón y pagar. Tu carrito se conservará.
        </p>
      )}

      <div className="space-y-2">
        {!esCliente ? (
          <Link to="/iniciar-sesion" state={{ desde: '/carrito' }} className={claseEnlaceBoton}>
            Inicia sesión para pagar
          </Link>
        ) : vacio || hayProblemas ? (
          <Boton disabled className="w-full">
            Continuar con el pago
          </Boton>
        ) : (
          <Link to="/checkout" className={claseEnlaceBoton}>
            Continuar con el pago
          </Link>
        )}

        {hayProblemas && (
          <p className="text-xs text-red-600">Resuelve los avisos de tus productos para continuar.</p>
        )}
      </div>
    </aside>
  );
}