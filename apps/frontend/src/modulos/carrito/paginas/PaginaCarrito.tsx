import { Link, Navigate } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
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
    <main className="mx-auto max-w-7xl p-6">
      <h1 className="mb-6 text-2xl font-semibold">Tu carrito</h1>

      {ajustes.length > 0 && (
        <div role="status" className="mb-4 rounded-md bg-amber-50 p-4 text-sm text-amber-800">
          <p className="font-medium">Ajustamos algunos productos de tu carrito por falta de existencias:</p>
          <ul className="mt-1 list-disc pl-5">
            {ajustes.map((a) => (
              <li key={a.idVariante}>
                SKU {a.sku}: pediste {a.solicitada}, quedaron {a.aplicada}.
              </li>
            ))}
          </ul>
          <button type="button" onClick={limpiarAjustes} className="mt-2 underline">
            Entendido
          </button>
        </div>
      )}

      {errorAccion && (
        <p role="alert" className="mb-4 rounded-md bg-red-50 p-3 text-sm text-red-700">
          {normalizarError(errorAccion).mensaje}
        </p>
      )}

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando tu carrito..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <div>
          <EstadoVacio titulo="Tu carrito está vacío" descripcion="Agrega productos desde el catálogo." />
          <p className="text-center">
            <Link to="/catalogo" className="text-sm font-medium text-indigo-600 hover:underline">
              Ir al catálogo
            </Link>
          </p>
        </div>
      ) : (
        <div className="grid gap-8 lg:grid-cols-[1fr_22rem]">
          <section aria-label="Productos del carrito">
            <ul className="divide-y divide-gray-200 rounded-lg border border-gray-200 bg-white px-4">
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
          </section>

          <ResumenCarrito carrito={consulta.data} acciones={acciones} esCliente={esCliente} />
        </div>
      )}
    </main>
  );
}