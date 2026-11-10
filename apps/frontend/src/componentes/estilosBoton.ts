export type VarianteBoton = 'primario' | 'secundario' | 'peligro';

const BASE =
  'inline-flex min-h-11 items-center justify-center gap-2 rounded-control px-4 py-2 text-sm font-semibold transition-colors duration-150 motion-reduce:transition-none disabled:cursor-not-allowed disabled:opacity-60 sm:min-h-10';

// El primario usa marca-700: el blanco sobre marca-600 no llega a 4,5:1.
const VARIANTES: Record<VarianteBoton, string> = {
  primario: 'bg-marca-700 text-white shadow-sm hover:bg-marca-800 active:bg-marca-900 disabled:hover:bg-marca-700',
  secundario:
    'border border-slate-300 bg-white text-slate-700 shadow-sm hover:border-slate-400 hover:bg-slate-50 active:bg-slate-100 disabled:hover:bg-white',
  peligro: 'bg-red-600 text-white shadow-sm hover:bg-red-700 active:bg-red-800 disabled:hover:bg-red-600',
};

/** Clases de botón; sirven también para un `Link` que debe verse como botón. */
export function claseBoton(variante: VarianteBoton = 'primario', extra = ''): string {
  return `${BASE} ${VARIANTES[variante]} ${extra}`;
}
