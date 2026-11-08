import { Link } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { formatearFechaHora, formatearMoneda } from '../../../utilidades/formato';
import { InsigniaEstado } from '../componentes/InsigniaEstado';
import { ESTADOS_PEDIDO, ETIQUETA_ESTADO } from '../constante';
import { useMisPedidos } from '../hooks/usePedidos';

const TAMANO_PAGINA = 10;

export function PaginaMisPedidos() {
  const { params, actualizar } = useParametrosUrl();

  const estado = ESTADOS_PEDIDO.find((e) => e === params.get('estado'));
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useMisPedidos({ estado, pagina, registroPorPagina: TAMANO_PAGINA });

  return (
    <main className="mx-auto max-w-4xl p-6">
      <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
        <h1 className="text-2xl font-semibold">Mis pedidos</h1>

        <div>
          <label htmlFor="filtro-estado" className="mb-1 block text-sm font-medium text-gray-700">
            Estado
          </label>
          <select
            id="filtro-estado"
            value={estado ?? ''}
            onChange={(e) => actualizar({ estado: e.target.value || undefined })}
            className="rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="">Todos</option>
            {ESTADOS_PEDIDO.map((e) => (
              <option key={e} value={e}>
                {ETIQUETA_ESTADO[e]}
              </option>
            ))}
          </select>
        </div>
      </div>

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando tus pedidos..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <div>
          <EstadoVacio
            titulo={estado ? 'No tienes pedidos con ese estado' : 'Aún no tienes pedidos'}
            descripcion="Cuando hagas una compra aparecerá aquí."
          />
          <p className="text-center">
            <Link to="/catalogo" className="text-sm font-medium text-indigo-600 hover:underline">
              Ir al catálogo
            </Link>
          </p>
        </div>
      ) : (
        <>
          <ul className={`space-y-3 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            {consulta.data.items.map((p) => (
              <li key={p.idPedido}>
                <Link
                  to={`/mis-pedidos/${p.idPedido}`}
                  className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-gray-200 bg-white p-4 hover:shadow-md"
                >
                  <div>
                    <p className="font-medium">{p.numeroPedido}</p>
                    <p className="text-sm text-gray-500">
                      {formatearFechaHora(p.fechaCreacion)} · {p.unidades} {p.unidades === 1 ? 'unidad' : 'unidades'}
                    </p>
                  </div>
                  <div className="flex items-center gap-4">
                    <InsigniaEstado estado={p.estado} />
                    <span className="font-semibold">{formatearMoneda(p.total)}</span>
                  </div>
                </Link>
              </li>
            ))}
          </ul>

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
    </main>
  );
}