import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { OPCIONES_ORDEN, type CambiosFiltros } from '../hooks/useFiltrosCatalogo';
import type { CategoriaPublica, FiltrosCatalogo } from '../tipos/catalogo';

interface Propiedades {
  filtros: FiltrosCatalogo;
  categorias: CategoriaPublica[];
  alCambiar: (cambios: CambiosFiltros) => void;
  alLimpiar: () => void;
}

const claseEtiqueta = 'mb-1.5 block text-sm font-medium text-gray-700';

export function PanelFiltros({ filtros, categorias, alCambiar, alLimpiar }: Propiedades) {
  const [texto, setTexto] = useState(filtros.texto ?? '');
  const [minimo, setMinimo] = useState(filtros.precioMinimo?.toString() ?? '');
  const [maximo, setMaximo] = useState(filtros.precioMaximo?.toString() ?? '');
  const [errorPrecio, setErrorPrecio] = useState<string | null>(null);
  const [abiertoMovil, setAbiertoMovil] = useState(false);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();

    const min = minimo.trim() === '' ? undefined : Number(minimo);
    const max = maximo.trim() === '' ? undefined : Number(maximo);

    const invalido = (v: number | undefined) => v !== undefined && (Number.isNaN(v) || v < 0);
    if (invalido(min) || invalido(max)) {
      setErrorPrecio('Ingresa precios válidos.');
      return;
    }
    if (min !== undefined && max !== undefined && min > max) {
      setErrorPrecio('El precio mínimo no puede ser mayor al máximo.');
      return;
    }

    setErrorPrecio(null);
    alCambiar({ texto: texto.trim() || undefined, min: min?.toString(), max: max?.toString() });
  };

  const limpiar = () => {
    setTexto('');
    setMinimo('');
    setMaximo('');
    setErrorPrecio(null);
    alLimpiar();
  };

  const filtrosActivos = [
    filtros.texto,
    filtros.idCategoria,
    filtros.precioMinimo ?? filtros.precioMaximo,
    filtros.soloDisponibles || undefined,
  ].filter((f) => f !== undefined && f !== '').length;

  return (
    <aside aria-label="Filtros del catálogo" className="lg:sticky lg:top-20 lg:self-start">
      <button
        type="button"
        aria-expanded={abiertoMovil}
        aria-controls="panel-filtros"
        onClick={() => setAbiertoMovil((a) => !a)}
        className="tarjeta flex min-h-11 w-full items-center justify-between px-4 text-sm font-medium text-gray-800 lg:hidden"
      >
        <span className="flex items-center gap-2">
          <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5 text-gray-500">
            <path strokeLinecap="round" d="M4 6h16M7 12h10M10 18h4" />
          </svg>
          Filtros y orden
          {filtrosActivos > 0 && (
            <span className="rounded-full bg-marca-600 px-2 py-0.5 text-xs font-semibold text-white">
              {filtrosActivos}
              <span className="sr-only"> activos</span>
            </span>
          )}
        </span>
        <svg
          aria-hidden="true"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          className={`h-5 w-5 text-gray-500 transition-transform duration-150 motion-reduce:transition-none ${abiertoMovil ? 'rotate-180' : ''}`}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="m6 9 6 6 6-6" />
        </svg>
      </button>

      <div id="panel-filtros" className={`${abiertoMovil ? 'block' : 'hidden'} tarjeta mt-2 space-y-5 p-4 lg:mt-0 lg:block`}>
        <h2 className="hidden text-xs font-semibold uppercase tracking-wide text-gray-600 lg:block">Filtros</h2>

        <form onSubmit={aplicar} noValidate className="space-y-4">
          <CampoFormulario
            etiqueta="Buscar"
            type="search"
            enterKeyHint="search"
            placeholder="Nombre, descripción o SKU"
            maxLength={100}
            value={texto}
            onChange={(e) => setTexto(e.target.value)}
          />

          <div className="grid grid-cols-2 gap-3">
            <CampoFormulario
              etiqueta="Precio mín."
              type="number"
              inputMode="decimal"
              min={0}
              step="0.01"
              placeholder="Q 0"
              value={minimo}
              onChange={(e) => setMinimo(e.target.value)}
            />
            <CampoFormulario
              etiqueta="Precio máx."
              type="number"
              inputMode="decimal"
              min={0}
              step="0.01"
              placeholder="Sin límite"
              value={maximo}
              onChange={(e) => setMaximo(e.target.value)}
              error={errorPrecio ?? undefined}
            />
          </div>

          <Boton type="submit" className="w-full">
            Aplicar
          </Boton>
        </form>

        <div className="space-y-4 border-t border-gray-100 pt-4">
          <div>
            <label htmlFor="filtro-categoria" className={claseEtiqueta}>
              Categoría
            </label>
            <select
              id="filtro-categoria"
              className="control"
              value={filtros.idCategoria ?? ''}
              onChange={(e) => alCambiar({ categoria: e.target.value || undefined })}
            >
              <option value="">Todas</option>
              {categorias.map((c) => (
                <option key={c.idCategoria} value={c.idCategoria}>
                  {c.nombre}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="filtro-orden" className={claseEtiqueta}>
              Ordenar por
            </label>
            <select
              id="filtro-orden"
              className="control"
              value={`${filtros.ordenarPor}|${filtros.direccion}`}
              onChange={(e) => {
                const [orden, dir] = e.target.value.split('|');
                alCambiar({ orden, dir });
              }}
            >
              {OPCIONES_ORDEN.map((o) => (
                <option key={o.valor} value={o.valor}>
                  {o.etiqueta}
                </option>
              ))}
            </select>
          </div>

          <label className="flex min-h-11 cursor-pointer items-center gap-3 text-sm text-gray-700 sm:min-h-0">
            <input
              type="checkbox"
              className="h-4 w-4"
              checked={filtros.soloDisponibles ?? false}
              onChange={(e) => alCambiar({ disponibles: e.target.checked ? 'true' : undefined })}
            />
            Solo productos disponibles
          </label>
        </div>

        <Boton variante="secundario" onClick={limpiar} className="w-full">
          Limpiar filtros
        </Boton>
      </div>
    </aside>
  );
}
