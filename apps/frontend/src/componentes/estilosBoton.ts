export type VarianteBoton = 'primario' | 'secundario' | 'peligro';

const BASE =
  'inline-flex min-h-11 items-center justify-center gap-2 rounded-control px-4 py-2 text-sm font-medium transition-colors duration-150 motion-reduce:transition-none disabled:cursor-not-allowed disabled:opacity-60 sm:min-h-10';

const VARIANTES: Record<VarianteBoton, string> = {
  primario: 'bg-marca-600 text-white shadow-sm hover:bg-marca-700 active:bg-marca-800 disabled:hover:bg-marca-600',
  secundario:
    'border border-gray-300 bg-white text-gray-700 shadow-sm hover:border-gray-400 hover:bg-gray-50 active:bg-gray-100 disabled:hover:bg-white',
  peligro: 'bg-red-600 text-white shadow-sm hover:bg-red-700 active:bg-red-800 disabled:hover:bg-red-600',
};

/** Clases de botón; sirven también para un `Link` que debe verse como botón. */
export function claseBoton(variante: VarianteBoton = 'primario', extra = ''): string {
  return `${BASE} ${VARIANTES[variante]} ${extra}`;
}
