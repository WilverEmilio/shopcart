import { Link } from 'react-router-dom';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import { formatearMoneda } from '../../../utilidades/formato';
import type { ProductoCatalogo } from '../tipos/catalogo';

export function TarjetaProducto({ producto }: { producto: ProductoCatalogo }) {
  const agotado = producto.disponible <= 0;
  const precio =
    producto.precioDesde === producto.precioHasta
      ? formatearMoneda(producto.precioDesde)
      : `Desde ${formatearMoneda(producto.precioDesde)}`;

  return (
    <Link
      to={`/catalogo/${producto.idProducto}`}
      className="group flex flex-col overflow-hidden rounded-lg border border-gray-200 bg-white transition hover:shadow-md"
    >
      <div className="relative aspect-square bg-gray-100">
        <ImagenProducto url={producto.imagenPrincipal} alt={producto.nombre} className="h-full w-full object-cover" />
        {agotado && (
          <span className="absolute left-2 top-2 rounded bg-gray-900/80 px-2 py-1 text-xs font-medium text-white">
            Agotado
          </span>
        )}
      </div>

      <div className="flex flex-1 flex-col gap-1 p-4">
        <span className="text-xs uppercase tracking-wide text-gray-500">{producto.categoria}</span>
        <h2 className="font-medium text-gray-900 group-hover:text-indigo-600">{producto.nombre}</h2>
        <p className="mt-auto pt-2 text-lg font-semibold">{precio}</p>
      </div>
    </Link>
  );
}