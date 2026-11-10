import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { claseBoton } from '../../../componentes/estilosBoton';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda } from '../../../utilidades/formato';
import type { AccionesCarrito } from '../hooks/useCarrito';
import type { Carrito } from '../tipos/carrito';

interface Propiedades {
  carrito: Carrito;
  acciones: AccionesCarrito;
  esCliente: boolean;
}

const claseEnlaceBoton = claseBoton('primario', 'w-full');

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
    <aside className="tarjeta space-y-4 p-5 lg:sticky lg:top-20 lg:self-start">
      <h2 className="text-lg font-semibold">Resumen</h2>

      <dl className="space-y-2 text-sm">
        <div className="flex justify-between">
          <dt className="text-slate-600">Subtotal</dt>
          <dd className="tabular-nums">{formatearMoneda(carrito.subtotal)}</dd>
        </div>

        {carrito.descuento > 0 && (
          <div className="flex justify-between text-green-700">
            <dt>Descuento</dt>
            <dd className="tabular-nums">−{formatearMoneda(carrito.descuento)}</dd>
          </div>
        )}

        <div className="flex items-baseline justify-between border-t border-slate-200 pt-3 font-semibold text-slate-900">
          <dt className="text-base">Total</dt>
          <dd className="precio text-2xl">{formatearMoneda(carrito.total)}</dd>
        </div>
        <p className="text-xs text-slate-600">Incluye IVA de {formatearMoneda(carrito.iva)}. El envío se calcula al pagar.</p>
      </dl>

      {esCliente ? (
        <div className="border-t border-slate-200 pt-4">
          {carrito.cupon ? (
            <div className="space-y-2 text-sm">
              <div className="flex items-center justify-between gap-2 rounded-control border border-dashed border-green-300 bg-green-50 px-3 py-2">
                <span className="text-green-800">
                  Cupón <strong className="font-mono">{carrito.cupon.codigo}</strong>
                </span>
                <button
                  type="button"
                  disabled={acciones.ocupado}
                  onClick={() => {
                    acciones.reiniciarErrores();
                    acciones.quitarCupon.mutate();
                  }}
                  className="min-h-9 rounded-control px-2 font-medium text-red-700 hover:bg-red-100 disabled:opacity-50"
                >
                  Quitar
                </button>
              </div>
              {!carrito.cupon.valido && carrito.cupon.mensaje && (
                <p role="alert" className="text-amber-800">
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
                  className="font-mono uppercase"
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
        <p className="border-t border-slate-200 pt-4 text-sm text-slate-600">
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
          <p className="text-xs text-red-700">Resuelve los avisos de tus productos para continuar.</p>
        )}
      </div>
    </aside>
  );
}