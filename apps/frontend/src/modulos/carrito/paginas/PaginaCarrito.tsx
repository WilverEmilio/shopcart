import { Link, Navigate } from 'react-router-dom';
import { Esqueleto } from '../../../componentes/EstadoCarga';
import { claseBoton } from '../../../componentes/estilosBoton';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { useCarritoEstado } from '../../../estados/carritoEstado';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { normalizarError } from '../../../servicios/errorServicio';
import { ItemCarritoFila } from '../componentes/ItemCarritoFila';
import { ResumenCarrito } from '../componentes/ResumenCarrito';
import { useAccionesCarrito, useCarrito } from '../hooks/useCarrito';

export function PaginaCarrito() {
  const usuario = useSesionEstado((e) => e.usuario);
  const esCliente = usuario?.rol === 'Cliente';
  const esGestor = usuario !== null && !esCliente;

  const consulta = useCarrito(!esGestor);
  const acciones = useAccionesCarrito();
  const ajustes = useCarritoEstado((e) => e.ajustesFusion);
  const limpiarAjustes = useCarritoEstado((e) => e.limpiarAjustes);

  if (esGestor) return <Navigate to="/sin-permiso" replace />;

  const errorAccion = acciones.cambiarCantidad.error ?? acciones.eliminar.error ?? acciones.quitarCupon.error;

  return (
    <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 sm:py-8">
      <h1 className="mb-6 text-2xl font-bold tracking-tight sm:text-3xl">Tu carrito</h1>

      {ajustes.length > 0 && (
        <div role="status" className="mb-4 rounded-tarjeta border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
          <p className="font-medium">Ajustamos algunos productos de tu carrito por falta de existencias:</p>
          <ul className="mt-1 list-disc pl-5">
            {ajustes.map((a) => (
              <li key={a.idVariante}>
                SKU {a.sku}: pediste {a.solicitada}, quedaron {a.aplicada}.
              </li>
            ))}
          </ul>
          <button type="button" onClick={limpiarAjustes} className="mt-2 min-h-9 font-medium underline underline-offset-2">
            Entendido
          </button>
        </div>
      )}

      {errorAccion && (
        <p role="alert" className="mb-4 rounded-tarjeta border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {normalizarError(errorAccion).mensaje}
        </p>
      )}

      {consulta.isPending ? (
        <div role="status" className="grid gap-8 lg:grid-cols-[1fr_22rem]">
          <span className="sr-only">Cargando tu carrito...</span>
          <div className="tarjeta divide-y divide-gray-200 px-4 sm:px-5">
            {Array.from({ length: 3 }, (_, i) => (
              <div key={i} className="flex gap-3 py-4 sm:gap-4 sm:py-5">
                <Esqueleto className="h-20 w-20 shrink-0 sm:h-24 sm:w-24" />
                <div className="flex-1 space-y-2">
                  <Esqueleto className="h-4 w-3/5" />
                  <Esqueleto className="h-3 w-1/3" />
                  <Esqueleto className="mt-4 h-10 w-32" />
                </div>
              </div>
            ))}
          </div>
          <Esqueleto className="h-64 rounded-tarjeta" />
        </div>
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <div className="tarjeta">
          <EstadoVacio
            titulo="Tu carrito está vacío"
            descripcion="Agrega productos desde el catálogo."
            accion={
              <Link to="/catalogo" className={claseBoton('primario')}>
                Ir al catálogo
              </Link>
            }
          />
        </div>
      ) : (
        <div className="grid gap-8 lg:grid-cols-[1fr_22rem]">
          <section aria-label="Productos del carrito">
            <ul className="tarjeta divide-y divide-gray-200 px-4 sm:px-5">
              {consulta.data.items.map((item) => (
                <ItemCarritoFila
                  key={item.idVariante}
                  item={item}
                  ocupado={acciones.ocupado}
                  alCambiarCantidad={(cantidad) => {
                    acciones.reiniciarErrores();
                    acciones.cambiarCantidad.mutate({ idVariante: item.idVariante, cantidad });
                  }}
                  alEliminar={() => {
                    acciones.reiniciarErrores();
                    acciones.eliminar.mutate(item.idVariante);
                  }}
                />
              ))}
            </ul>
            <Link to="/catalogo" className="mt-4 inline-flex min-h-10 items-center text-sm font-medium text-marca-700 hover:underline">
              ← Seguir comprando
            </Link>
          </section>

          <ResumenCarrito carrito={consulta.data} acciones={acciones} esCliente={esCliente} />
        </div>
      )}
    </main>
  );
}