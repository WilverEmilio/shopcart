interface Propiedades {
  pagina: number;
  tamanoPagina: number;
  totalRegistros: number;
  alCambiar: (pagina: number) => void;
}

export function Paginador({ pagina, tamanoPagina, totalRegistros, alCambiar }: Propiedades) {
  const totalPaginas = Math.max(1, Math.ceil(totalRegistros / tamanoPagina));
  if (totalPaginas <= 1) return null;

  const inicio = Math.max(1, Math.min(pagina - 2, totalPaginas - 4));
  const fin = Math.min(totalPaginas, inicio + 4);
  const paginas = Array.from({ length: fin - inicio + 1 }, (_, i) => inicio + i);

  const base =
    'inline-flex min-h-10 min-w-10 items-center justify-center rounded-control border px-3 text-sm font-medium transition-colors duration-150 motion-reduce:transition-none disabled:cursor-not-allowed disabled:opacity-50';
  const normal = 'border-slate-300 bg-white text-slate-700 hover:bg-slate-50 disabled:hover:bg-white';

  return (
    <nav aria-label="Paginación" className="mt-8 flex flex-wrap items-center justify-center gap-2">
      <button type="button" className={`${base} ${normal}`} disabled={pagina <= 1} onClick={() => alCambiar(pagina - 1)}>
        <span aria-hidden="true">‹</span>
        <span className="ml-1 hidden sm:inline">Anterior</span>
        <span className="sr-only sm:hidden">Anterior</span>
      </button>

      {paginas.map((p) => (
        <button
          key={p}
          type="button"
          aria-current={p === pagina ? 'page' : undefined}
          className={`${base} ${p === pagina ? 'border-marca-700 bg-marca-700 text-white' : normal}`}
          onClick={() => alCambiar(p)}
        >
          {p}
        </button>
      ))}

      <button type="button" className={`${base} ${normal}`} disabled={pagina >= totalPaginas} onClick={() => alCambiar(pagina + 1)}>
        <span className="mr-1 hidden sm:inline">Siguiente</span>
        <span className="sr-only sm:hidden">Siguiente</span>
        <span aria-hidden="true">›</span>
      </button>

      <span className="w-full text-center text-xs text-slate-600">
        Página {pagina} de {totalPaginas}
      </span>
    </nav>
  );
}
