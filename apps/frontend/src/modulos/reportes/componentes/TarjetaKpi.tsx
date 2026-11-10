import type { ReactNode } from 'react';

interface Propiedades {
  titulo: string;
  valor: string;
  detalle?: ReactNode;
  variacion?: number | null;
}

export function TarjetaKpi({ titulo, valor, detalle, variacion }: Propiedades) {
  const sube = variacion !== undefined && variacion !== null && variacion >= 0;

  return (
    <div className="tarjeta flex flex-col p-4 sm:p-5">
      <p className="text-sm font-medium text-slate-600">{titulo}</p>
      <p className="mt-2 precio text-3xl">{valor}</p>

      {variacion !== undefined && (
        <p className="mt-2">
          {variacion === null ? (
            <span className="text-xs text-slate-600">Sin periodo anterior para comparar</span>
          ) : (
            <span
              className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold tabular-nums ${
                sube ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
              }`}
            >
              <span aria-hidden="true">{sube ? '▲' : '▼'}</span>
              <span className="sr-only">{sube ? 'Sube' : 'Baja'}</span>
              {Math.abs(variacion).toFixed(1)} %<span className="font-normal"> vs periodo anterior</span>
            </span>
          )}
        </p>
      )}

      {detalle && <p className="mt-auto pt-2 text-xs text-slate-600">{detalle}</p>}
    </div>
  );
}
