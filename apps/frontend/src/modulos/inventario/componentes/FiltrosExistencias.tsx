import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import type { CategoriaPublica } from '../../catalogo/tipos/catalogo';

export const OPCIONES_ORDEN_EXISTENCIAS = [
  { valor: 'Producto|ASC', etiqueta: 'Producto (A-Z)' },
  { valor: 'Producto|DESC', etiqueta: 'Producto (Z-A)' },
  { valor: 'SKU|ASC', etiqueta: 'SKU (A-Z)' },
  { valor: 'SKU|DESC', etiqueta: 'SKU (Z-A)' },
  { valor: 'Disponible|ASC', etiqueta: 'Disponible: menor a mayor' },
  { valor: 'Disponible|DESC', etiqueta: 'Disponible: mayor a menor' },
] as const;

interface Propiedades {
  texto: string;
  idCategoria: number | undefined;
  soloSinDisponibilidad: boolean;
  activo: string; // '' | 'true' | 'false'
  orden: string;
  categorias: CategoriaPublica[];
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

const claseSelect =
  'w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500';

export function FiltrosExistencias({
  texto, idCategoria, soloSinDisponibilidad, activo, orden, categorias, alCambiar, alLimpiar,
}: Propiedades) {
  const [textoLocal, setTextoLocal] = useState(texto);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    alCambiar({ texto: textoLocal.trim() || undefined });
  };

  return (
    <form onSubmit={aplicar} noValidate className="space-y-4 rounded-lg border border-gray-200 bg-white p-4">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <CampoFormulario
          etiqueta="Buscar"
          type="search"
          placeholder="SKU o nombre del producto"
          maxLength={100}
          value={textoLocal}
          onChange={(e) => setTextoLocal(e.target.value)}
        />

        <div>
          <label htmlFor="inv-categoria" className="mb-1 block text-sm font-medium text-gray-700">
            Categoría
          </label>
          <select
            id="inv-categoria"
            className={claseSelect}
            value={idCategoria ?? ''}
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
          <label htmlFor="inv-activo" className="mb-1 block text-sm font-medium text-gray-700">
            Estado
          </label>
          <select id="inv-activo" className={claseSelect} value={activo} onChange={(e) => alCambiar({ activo: e.target.value || undefined })}>
            <option value="">Todos</option>
            <option value="true">Activas</option>
            <option value="false">Inactivas</option>
          </select>
        </div>

        <div>
          <label htmlFor="inv-orden" className="mb-1 block text-sm font-medium text-gray-700">
            Ordenar por
          </label>
          <select id="inv-orden" className={claseSelect} value={orden} onChange={(e) => alCambiar({ orden: e.target.value })}>
            {OPCIONES_ORDEN_EXISTENCIAS.map((o) => (
              <option key={o.valor} value={o.valor}>
                {o.etiqueta}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-4">
        <label className="flex items-center gap-2 text-sm text-gray-700">
          <input
            type="checkbox"
            checked={soloSinDisponibilidad}
            onChange={(e) => alCambiar({ sin: e.target.checked ? 'true' : undefined })}
          />
          Solo sin disponibilidad
        </label>
        <Boton type="submit">Aplicar</Boton>
        <Boton
          variante="secundario"
          onClick={() => {
            setTextoLocal('');
            alLimpiar();
          }}
        >
          Limpiar filtros
        </Boton>
      </div>
    </form>
  );
}