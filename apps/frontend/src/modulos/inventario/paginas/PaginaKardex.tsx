import { Link } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { formatearFechaHora } from '../../../utilidades/formato';
import { FiltrosKardex } from '../componentes/FiltrosKardex';
import { NavegacionInventario } from '../componentes/NavegacionInventario';
import { CLASE_MOVIMIENTO, ETIQUETA_MOVIMIENTO, TIPOS_MOVIMIENTO } from '../constante';
import { useKardex } from '../hooks/useInventario';

const TAMANO_PAGINA = 20;

export function PaginaKardex() {
  const { params, actualizar, limpiar } = useParametrosUrl();

  const idVariante = Number(params.get('variante')) || undefined;
  const tipoMovimiento = TIPOS_MOVIMIENTO.find((t) => t === params.get('tipo'));
  const texto = params.get('texto') ?? '';
  const fechaDesde = params.get('desde') ?? '';
  const fechaHasta = params.get('hasta') ?? '';
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useKardex({
    idVariante,
    tipoMovimiento,
    texto: texto || undefined,
    fechaDesde: fechaDesde || undefined,
    fechaHasta: fechaHasta || undefined,
    pagina,
    registrosPorPagina: TAMANO_PAGINA,
  });

  return (
    <main className="mx-auto max-w-7xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      <h1 className="text-2xl font-bold sm:text-3xl">Inventario</h1>
      <NavegacionInventario />

      <p className="text-sm text-slate-600">
        Historial de entradas, salidas y ajustes. Es inmutable: los errores se corrigen con un nuevo ajuste.
      </p>

      {idVariante && (
        <p className="flex items-center justify-between gap-3 rounded-control border border-marca-100 bg-marca-50 p-3 text-sm text-marca-800">
          Mostrando solo los movimientos de la variante #{idVariante}.
          <button type="button" onClick={() => actualizar({ variante: undefined })} className="min-h-9 shrink-0 font-medium underline underline-offset-2">
            Quitar filtro
          </button>
        </p>
      )}

      <FiltrosKardex
        key={`${texto}|${fechaDesde}|${fechaHasta}`}
        texto={texto}
        tipo={tipoMovimiento ?? ''}
        fechaDesde={fechaDesde}
        fechaHasta={fechaHasta}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando movimientos..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="Sin movimientos" descripcion="No hay movimientos con esos filtros." />
      ) : (
        <>
          <p className="text-sm text-slate-600">{consulta.data.totalRegistros} movimientos</p>

          <div className={`tarjeta overflow-x-auto transition-opacity duration-150 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="tabla">
              <thead>
                <tr>
                  <th className="px-4 py-3">Fecha</th>
                  <th className="px-4 py-3">Producto</th>
                  <th className="px-4 py-3">Tipo</th>
                  <th className="px-4 py-3 text-right">Cantidad</th>
                  <th className="px-4 py-3 text-right">Existencia</th>
                  <th className="px-4 py-3">Motivo</th>
                  <th className="px-4 py-3">Referencia</th>
                  <th className="px-4 py-3">Usuario</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {consulta.data.items.map((m) => (
                  <tr key={m.idMovimiento}>
                    <td className="whitespace-nowrap px-4 py-3">{formatearFechaHora(m.fecha)}</td>
                    <td className="px-4 py-3">
                      <p>{m.producto}</p>
                      <p className="font-mono text-xs text-slate-500">{m.sku}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${CLASE_MOVIMIENTO[m.tipoMovimiento]}`}>
                        {ETIQUETA_MOVIMIENTO[m.tipoMovimiento]}
                      </span>
                    </td>
                    <td className={`px-4 py-3 text-right font-semibold ${m.cantidad > 0 ? 'text-green-700' : 'text-red-600'}`}>
                      {m.cantidad > 0 ? '+' : '−'}
                      {Math.abs(m.cantidad)}
                    </td>
                    <td className="px-4 py-3 text-right">{m.existenciaResultante}</td>
                    <td className="max-w-xs px-4 py-3 text-slate-600">{m.motivo}</td>
                    <td className="whitespace-nowrap px-4 py-3">
                      {m.tipoReferencia === 'PEDIDO' && m.idReferencia ? (
                        <Link to={`/gestion/pedidos/${m.idReferencia}`} className="font-medium text-marca-700 hover:underline">
                          Pedido #{m.idReferencia}
                        </Link>
                      ) : m.tipoReferencia === 'DEVOLUCION' ? (
                        `Devolución #${m.idReferencia}`
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="px-4 py-3 text-xs text-slate-500">{m.correoUsuario}</td>
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
    </main>
  );
}