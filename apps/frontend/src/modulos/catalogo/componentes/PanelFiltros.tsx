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

const claseSelect =
  'w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500';

export function PanelFiltros({ filtros, categorias, alCambiar, alLimpiar }: Propiedades) {
  const [texto, setTexto] = useState(filtros.texto ?? '');
  const [minimo, setMinimo] = useState(filtros.precioMinimo?.toString() ?? '');
  const [maximo, setMaximo] = useState(filtros.precioMaximo?.toString() ?? '');
  const [errorPrecio, setErrorPrecio] = useState<string | null>(null);

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

  return (
    <aside className="space-y-4 rounded-lg border border-gray-200 bg-white p-4 lg:self-start">
      <form onSubmit={aplicar} noValidate className="space-y-4">
        <CampoFormulario
          etiqueta="Buscar"
          type="search"
          placeholder="Nombre, descripción o SKU"
          maxLength={100}
          value={texto}
          onChange={(e) => setTexto(e.target.value)}
        />

        <div className="grid grid-cols-2 gap-2">
          <CampoFormulario etiqueta="Precio mín." type="number" min={0} step="0.01" value={minimo} onChange={(e) => setMinimo(e.target.value)} />
          <CampoFormulario etiqueta="Precio máx." type="number" min={0} step="0.01" value={maximo} onChange={(e) => setMaximo(e.target.value)} error={errorPrecio ?? undefined} />
        </div>

        <Boton type="submit" className="w-full">
          Aplicar
        </Boton>
      </form>

      <div>
        <label htmlFor="filtro-categoria" className="mb-1 block text-sm font-medium text-gray-700">
          Categoría
        </label>
        <select
          id="filtro-categoria"
          className={claseSelect}
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
        <label htmlFor="filtro-orden" className="mb-1 block text-sm font-medium text-gray-700">
          Ordenar por
        </label>
        <select
          id="filtro-orden"
          className={claseSelect}
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

      <label className="flex items-center gap-2 text-sm text-gray-700">
        <input
          type="checkbox"
          checked={filtros.soloDisponibles ?? false}
          onChange={(e) => alCambiar({ disponibles: e.target.checked ? 'true' : undefined })}
        />
        Solo productos disponibles
      </label>

      <Boton variante="secundario" onClick={limpiar} className="w-full">
        Limpiar filtros
      </Boton>
    </aside>
  );
}