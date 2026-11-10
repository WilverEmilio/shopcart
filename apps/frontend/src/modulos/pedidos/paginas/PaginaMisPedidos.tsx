import { Link } from 'react-router-dom';
import { Esqueleto } from '../../../componentes/EstadoCarga';
import { claseBoton } from '../../../componentes/estilosBoton';
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
    <main className="mx-auto max-w-4xl px-4 py-6 sm:px-6 sm:py-8">
      <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
        <h1 className="text-3xl font-bold sm:text-4xl">Mis pedidos</h1>

        <div className="w-full sm:w-56">
          <label htmlFor="filtro-estado" className="mb-1.5 block text-sm font-medium text-slate-700">
            Estado
          </label>
          <select
            id="filtro-estado"
            value={estado ?? ''}
            onChange={(e) => actualizar({ estado: e.target.value || undefined })}
            className="control"
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
        <div role="status" className="space-y-3">
          <span className="sr-only">Cargando tus pedidos...</span>
          {Array.from({ length: 4 }, (_, i) => (
            <div key={i} className="tarjeta flex items-center justify-between gap-4 p-4 sm:p-5">
              <div className="flex-1 space-y-2">
                <Esqueleto className="h-4 w-32" />
                <Esqueleto className="h-3 w-48" />
              </div>
              <Esqueleto className="h-6 w-24 rounded-full" />
            </div>
          ))}
        </div>
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <div className="tarjeta">
          <EstadoVacio
            titulo={estado ? 'No tienes pedidos con ese estado' : 'Aún no tienes pedidos'}
            descripcion="Cuando hagas una compra aparecerá aquí."
            accion={
              <Link to="/catalogo" className={claseBoton('primario')}>
                Ir al catálogo
              </Link>
            }
          />
        </div>
      ) : (
        <>
          <ul className={`space-y-3 transition-opacity duration-150 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            {consulta.data.items.map((p) => (
              <li key={p.idPedido}>
                <Link
                  to={`/mis-pedidos/${p.idPedido}`}
                  className="tarjeta group flex items-center gap-3 p-4 transition-shadow duration-150 hover:shadow-elevada motion-reduce:transition-none sm:p-5"
                >
                  <div className="flex min-w-0 flex-1 flex-wrap items-center justify-between gap-x-4 gap-y-2">
                    <div className="min-w-0">
                      <p className="font-semibold text-slate-900 group-hover:text-marca-700">{p.numeroPedido}</p>
                      <p className="text-sm text-slate-600">
                        {formatearFechaHora(p.fechaCreacion)} · {p.unidades} {p.unidades === 1 ? 'unidad' : 'unidades'}
                      </p>
                    </div>
                    <div className="flex items-center gap-4">
                      <InsigniaEstado estado={p.estado} />
                      <span className="precio">{formatearMoneda(p.total)}</span>
                    </div>
                  </div>
                  <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5 shrink-0 text-slate-400 group-hover:text-marca-600">
                    <path strokeLinecap="round" strokeLinejoin="round" d="m9 6 6 6-6 6" />
                  </svg>
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