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
  'h-8 w-8 rounded-md border border-gray-300 text-lg leading-none hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50';

export function ItemCarritoFila({ item, ocupado, alCambiarCantidad, alEliminar }: Propiedades) {
  const maximo = Math.min(999, Math.max(item.disponible, 0));
  const urlProducto = `/catalogo/${item.idProducto}`;

  return (
    <li className="flex gap-4 py-4">
      <Link to={urlProducto} className="h-24 w-24 shrink-0 overflow-hidden rounded-md border border-gray-200">
        <ImagenProducto url={item.imagen} alt={item.producto} className="h-full w-full object-cover" />
      </Link>

      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <Link to={urlProducto} className="font-medium text-gray-900 hover:text-indigo-600">
          {item.producto}
        </Link>
        {item.atributos && <p className="text-sm text-gray-500">{item.atributos}</p>}
        <p className="text-xs text-gray-400">SKU {item.sku}</p>

        {!item.vendible ? (
          <p role="alert" className="text-sm text-red-600">
            Este producto ya no está disponible para la venta. Quítalo para continuar.
          </p>
        ) : item.excedeExistencia ? (
          <p role="alert" className="text-sm text-amber-600">
            Solo hay {item.disponible} disponibles. Reduce la cantidad para continuar.
          </p>
        ) : null}

        <div className="mt-auto flex flex-wrap items-center gap-3 pt-2">
          <div className="flex items-center gap-2" role="group" aria-label="Cantidad">
            <button
              type="button"
              aria-label="Disminuir cantidad"
              className={claseBotonCantidad}
              disabled={ocupado || item.cantidad <= 1}
              onClick={() => alCambiarCantidad(item.cantidad - 1)}
            >
              −
            </button>
            <span className="w-8 text-center text-sm" aria-live="polite">
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
            className="text-sm text-red-600 hover:underline disabled:opacity-50"
          >
            Quitar
          </button>
        </div>
      </div>

      <div className="text-right">
        <p className="font-semibold">{formatearMoneda(item.subtotal)}</p>
        <p className="text-xs text-gray-500">{formatearMoneda(item.precio)} c/u</p>
      </div>
    </li>
  );
}