import type { ReactNode } from 'react';

interface Propiedades {
  titulo: string;
  valor: string;
  detalle?: ReactNode;
  variacion?: number | null;
}

export function TarjetaKpi({ titulo, valor, detalle, variacion }: Propiedades) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4">
      <p className="text-xs font-medium uppercase tracking-wide text-gray-500">{titulo}</p>
      <p className="mt-1 text-2xl font-semibold">{valor}</p>

      {variacion !== undefined && (
        <p className={`mt-1 text-xs font-medium ${variacion === null ? 'text-gray-400' : variacion >= 0 ? 'text-green-700' : 'text-red-600'}`}>
          {variacion === null
            ? 'Sin periodo anterior para comparar'
            : `${variacion >= 0 ? '▲' : '▼'} ${Math.abs(variacion).toFixed(1)} % vs periodo anterior`}
        </p>
      )}

      {detalle && <p className="mt-1 text-xs text-gray-500">{detalle}</p>}
    </div>
  );
}