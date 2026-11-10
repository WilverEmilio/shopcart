import { Link } from 'react-router-dom';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import { formatearMoneda } from '../../../utilidades/formato';
import type { ItemCarrito } from '../tipos/carrito';

interface Propiedades {
  item: ItemCarrito;
  ocupado: boolean;
  alCambiarCantidad: (cantidad: number) => void;
  alEliminar: () => void;
}

const claseBotonCantidad =
  'flex h-10 w-10 items-center justify-center text-lg leading-none text-gray-700 transition-colors hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent';

export function ItemCarritoFila({ item, ocupado, alCambiarCantidad, alEliminar }: Propiedades) {
  const maximo = Math.min(999, Math.max(item.disponible, 0));
  const urlProducto = `/catalogo/${item.idProducto}`;
  const conProblema = !item.vendible || item.excedeExistencia;

  return (
    <li className="flex gap-3 py-4 sm:gap-4 sm:py-5">
      <Link
        to={urlProducto}
        className={`h-20 w-20 shrink-0 overflow-hidden rounded-control border border-gray-200 bg-white sm:h-24 sm:w-24 ${conProblema ? 'opacity-70' : ''}`}
      >
        <ImagenProducto url={item.imagen} alt={item.producto} className="h-full w-full object-cover" />
      </Link>

      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <Link to={urlProducto} className="line-clamp-2 font-medium text-gray-900 hover:text-marca-700">
              {item.producto}
            </Link>
            {item.atributos && <p className="text-sm text-gray-600">{item.atributos}</p>}
            <p className="text-xs text-gray-500">SKU {item.sku}</p>
          </div>

          <div className="shrink-0 text-right">
            <p className="font-semibold tabular-nums text-gray-900">{formatearMoneda(item.subtotal)}</p>
            <p className="text-xs tabular-nums text-gray-600">{formatearMoneda(item.precio)} c/u</p>
          </div>
        </div>

        {!item.vendible ? (
          <p role="alert" className="mt-1 rounded-control bg-red-50 px-3 py-2 text-sm text-red-700">
            Este producto ya no está disponible para la venta. Quítalo para continuar.
          </p>
        ) : item.excedeExistencia ? (
          <p role="alert" className="mt-1 rounded-control bg-amber-50 px-3 py-2 text-sm text-amber-800">
            Solo hay {item.disponible} disponibles. Reduce la cantidad para continuar.
          </p>
        ) : null}

        <div className="mt-auto flex flex-wrap items-center justify-between gap-3 pt-2">
          <div
            className="inline-flex items-center overflow-hidden rounded-control border border-gray-300 bg-white"
            role="group"
            aria-label={`Cantidad de ${item.producto}`}
          >
            <button
              type="button"
              aria-label="Disminuir cantidad"
              className={claseBotonCantidad}
              disabled={ocupado || item.cantidad <= 1}
              onClick={() => alCambiarCantidad(item.cantidad - 1)}
            >
              −
            </button>
            <span className="flex h-10 w-10 items-center justify-center border-x border-gray-300 text-sm font-medium tabular-nums" aria-live="polite">
              {item.cantidad}
            </span>
            <button
              type="button"
              aria-label="Aumentar cantidad"
              className={claseBotonCantidad}
              disabled={ocupado || !item.vendible || item.cantidad >= maximo}
              onClick={() => alCambiarCantidad(item.cantidad + 1)}
            >
              +
            </button>
          </div>

          <button
            type="button"
            disabled={ocupado}
            onClick={alEliminar}
            className="inline-flex min-h-10 items-center gap-1.5 rounded-control px-2 text-sm font-medium text-red-700 transition-colors hover:bg-red-50 disabled:opacity-50"
          >
            <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 7h16M10 11v6M14 11v6M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2l1-12M9 7V4h6v3" />
            </svg>
            Quitar
            <span className="sr-only"> {item.producto}</span>
          </button>
        </div>
      </div>
    </li>
  );
}
