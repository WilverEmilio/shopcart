import type { ReactNode } from 'react';

interface Propiedades {
  titulo?: string;
  descripcion?: string;
  /** Acción siguiente opcional, por ejemplo un enlace "Ir al catálogo". */
  accion?: ReactNode;
}

export function EstadoVacio({
  titulo = 'Sin resultados',
  descripcion = 'No hay información para mostrar',
  accion,
}: Propiedades) {
  return (
    <div className="flex flex-col items-center px-6 py-12 text-center">
      <span aria-hidden="true" className="flex h-12 w-12 items-center justify-center rounded-full bg-marca-50 text-marca-700">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-6 w-6">
          <path strokeLinecap="round" strokeLinejoin="round" d="M20 7 12 3 4 7m16 0-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
        </svg>
      </span>
      <p className="mt-4 font-medium text-slate-900">{titulo}</p>
      <p className="mt-1 max-w-md text-sm text-slate-600">{descripcion}</p>
      {accion && <div className="mt-5">{accion}</div>}
    </div>
  );
}
