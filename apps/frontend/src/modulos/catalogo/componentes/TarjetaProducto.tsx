import { Link } from 'react-router-dom';
import { Esqueleto } from '../../../componentes/EstadoCarga';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import { formatearMoneda } from '../../../utilidades/formato';
import type { ProductoCatalogo } from '../tipos/catalogo';

export function TarjetaProducto({ producto }: { producto: ProductoCatalogo }) {
  const agotado = producto.disponible <= 0;
  const rango = producto.precioDesde !== producto.precioHasta;

  return (
    <Link
      to={`/catalogo/${producto.idProducto}`}
      className="tarjeta group flex flex-col overflow-hidden transition-shadow duration-200 hover:shadow-elevada motion-reduce:transition-none"
    >
      <div className="relative aspect-square overflow-hidden bg-slate-100">
        <ImagenProducto
          url={producto.imagenPrincipal}
          alt={producto.nombre}
          className={`h-full w-full object-cover transition-transform duration-300 group-hover:scale-105 motion-reduce:transition-none motion-reduce:group-hover:scale-100 ${agotado ? 'opacity-70 grayscale' : ''}`}
        />
        {agotado && (
          <span className="absolute left-2 top-2 rounded-full bg-slate-900/85 px-2.5 py-1 text-xs font-semibold text-white">
            Agotado
          </span>
        )}
      </div>

      <div className="flex flex-1 flex-col gap-1 p-3 sm:p-4">
        <span className="truncate text-xs font-medium text-marca-700">{producto.categoria}</span>
        <h2 className="line-clamp-2 font-sans text-sm font-medium leading-snug text-slate-900 group-hover:text-marca-800 sm:text-base">
          {producto.nombre}
        </h2>
        <p className="mt-auto pt-2">
          {rango && <span className="block text-xs text-slate-600">Desde</span>}
          <span className="precio text-lg sm:text-xl">{formatearMoneda(producto.precioDesde)}</span>
        </p>
      </div>
    </Link>
  );
}

export function TarjetaProductoEsqueleto() {
  return (
    <div className="tarjeta flex flex-col overflow-hidden">
      <Esqueleto className="aspect-square rounded-none" />
      <div className="space-y-2 p-3 sm:p-4">
        <Esqueleto className="h-3 w-1/3" />
        <Esqueleto className="h-4 w-4/5" />
        <Esqueleto className="mt-3 h-5 w-1/2" />
      </div>
    </div>
  );
}
