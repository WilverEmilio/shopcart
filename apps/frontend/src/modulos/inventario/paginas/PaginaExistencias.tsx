import { useState } from 'react';
import { Link } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { useCategoriasPublicas } from '../../catalogo/hooks/useCatalogo';
import { DialogoMovimiento, type TipoDialogoMovimiento } from '../componentes/DialogoMovimientos';
import { FiltrosExistencias } from '../componentes/FiltrosExistencias';
import { OPCIONES_ORDEN_EXISTENCIAS } from '../constante';
import { NavegacionInventario } from '../componentes/NavegacionInventario';
import { useExistencias } from '../hooks/useInventario';
import type { ExistenciaVariante, FiltrosExistencias as Filtros } from '../tipos/inventario';

const TAMANO_PAGINA = 20;
const claseBotonFila = 'rounded-md border border-gray-300 px-2 py-1 text-xs font-medium hover:bg-gray-100';

export function PaginaExistencias() {
  const { params, actualizar, limpiar } = useParametrosUrl();
  const categorias = useCategoriasPublicas();

  const [movimiento, setMovimiento] = useState<{ variante: ExistenciaVariante; tipo: TipoDialogoMovimiento } | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);

  const texto = params.get('texto') ?? '';
  const idCategoria = Number(params.get('categoria')) || undefined;
  const soloSin = params.get('sin') === 'true';
  const activoParam = params.get('activo') ?? '';
  const activo = activoParam === 'true' ? true : activoParam === 'false' ? false : undefined;
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const orden = OPCIONES_ORDEN_EXISTENCIAS.find((o) => o.valor === params.get('orden'))?.valor ?? 'Producto|ASC';
  const [ordenarPor, direccion] = orden.split('|') as [Filtros['ordenarPor'], Filtros['direccion']];

  const consulta = useExistencias({
    texto: texto || undefined,
    idCategoria,
    soloSinDisponibilidad: soloSin,
    activo,
    ordenarPor,
    direccion,
    pagina,
    registrosPorPagina: TAMANO_PAGINA,
  });

  const claseDisponible = (n: number) =>
    n <= 0 ? 'font-semibold text-red-600' : n <= 5 ? 'font-semibold text-amber-600' : '';

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <h1 className="text-2xl font-semibold">Inventario</h1>
      <NavegacionInventario />

      <p className="text-sm text-gray-500">
        Disponible = existencia física − unidades reservadas por pagos en curso.
      </p>

      {aviso && (
        <p role="status" className="flex items-center justify-between rounded-md bg-green-50 p-3 text-sm text-green-800">
          {aviso}
          <button type="button" onClick={() => setAviso(null)} className="underline">
            Cerrar
          </button>
        </p>
      )}

      <FiltrosExistencias
        key={texto}
        texto={texto}
        idCategoria={idCategoria}
        soloSinDisponibilidad={soloSin}
        activo={activoParam}
        orden={orden}
        categorias={categorias.data ?? []}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando existencias..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="Sin resultados" descripcion="Prueba con otros filtros." />
      ) : (
        <>
          <p className="text-sm text-gray-500">
            {consulta.data.totalRegistros} {consulta.data.totalRegistros === 1 ? 'variante' : 'variantes'}
          </p>

          <div className={`overflow-x-auto rounded-lg border border-gray-200 bg-white ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">SKU</th>
                  <th className="px-4 py-3">Producto</th>
                  <th className="px-4 py-3">Categoría</th>
                  <th className="px-4 py-3 text-right">Física</th>
                  <th className="px-4 py-3 text-right">Reservada</th>
                  <th className="px-4 py-3 text-right">Disponible</th>
                  <th className="px-4 py-3">Estado</th>
                  <th className="px-4 py-3">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((v) => (
                  <tr key={v.idVariante} className="hover:bg-gray-50">
                    <td className="whitespace-nowrap px-4 py-3 font-mono text-xs">{v.sku}</td>
                    <td className="px-4 py-3">{v.producto}</td>
                    <td className="px-4 py-3 text-gray-600">{v.categoria}</td>
                    <td className="px-4 py-3 text-right">{v.existenciaFisica}</td>
                    <td className="px-4 py-3 text-right">{v.existenciaReservada}</td>
                    <td className={`px-4 py-3 text-right ${claseDisponible(v.existenciaDisponible)}`}>{v.existenciaDisponible}</td>
                    <td className="px-4 py-3">{v.activo ? 'Activa' : <span className="text-gray-400">Inactiva</span>}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        <button type="button" className={claseBotonFila} onClick={() => setMovimiento({ variante: v, tipo: 'entrada' })}>
                          Entrada
                        </button>
                        <button type="button" className={claseBotonFila} onClick={() => setMovimiento({ variante: v, tipo: 'ajuste' })}>
                          Ajuste
                        </button>
                        <Link to={`/gestion/inventario/kardex?variante=${v.idVariante}`} className={claseBotonFila}>
                          Kardex
                        </Link>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Paginador
            pagina={consulta.data.pagina}
            tamanoPagina={consulta.data.tamanoPagina}
            totalRegistros={consulta.data.totalRegistros}
            alCambiar={(p) => {
              actualizar({ pagina: String(p) });
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
          />
        </>
      )}

      <DialogoMovimiento
        variante={movimiento?.variante ?? null}
        tipo={movimiento?.tipo ?? 'entrada'}
        alCerrar={() => setMovimiento(null)}
        alRegistrado={setAviso}
      />
    </main>
  );
}