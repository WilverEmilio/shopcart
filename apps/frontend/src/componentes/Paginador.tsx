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

  const base = 'rounded-md border px-3 py-1 text-sm disabled:cursor-not-allowed disabled:opacity-50';

  return (
    <nav aria-label="Paginación" className="mt-6 flex flex-wrap items-center justify-center gap-2">
      <button type="button" className={`${base} border-gray-300 hover:bg-gray-100`} disabled={pagina <= 1} onClick={() => alCambiar(pagina - 1)}>
        Anterior
      </button>

      {paginas.map((p) => (
        <button
          key={p}
          type="button"
          aria-current={p === pagina ? 'page' : undefined}
          className={`${base} ${p === pagina ? 'border-indigo-600 bg-indigo-600 text-white' : 'border-gray-300 hover:bg-gray-100'}`}
          onClick={() => alCambiar(p)}
        >
          {p}
        </button>
      ))}

      <button type="button" className={`${base} border-gray-300 hover:bg-gray-100`} disabled={pagina >= totalPaginas} onClick={() => alCambiar(pagina + 1)}>
        Siguiente
      </button>

      <span className="w-full text-center text-xs text-gray-500">
        Página {pagina} de {totalPaginas}
      </span>
    </nav>
  );
}