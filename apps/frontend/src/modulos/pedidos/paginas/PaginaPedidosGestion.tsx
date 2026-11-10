import { Link } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { formatearFechaHora, formatearMoneda } from '../../../utilidades/formato';
import { FiltrosPedidosGestion } from '../componentes/FiltrosPedidosGestion';
import { InsigniaEstado } from '../componentes/InsigniaEstado';
import { ESTADOS_PEDIDO, OPCIONES_ORDEN_PEDIDOS } from '../constante';
import { usePedidosGestion } from '../hooks/usePedidos';
import type { FiltrosPedidosGestion as Filtros } from '../tipos/pedido';

const TAMANO_PAGINA = 20;

export function PaginaPedidosGestion() {
  const { params, actualizar, limpiar } = useParametrosUrl();

  const estado = ESTADOS_PEDIDO.find((e) => e === params.get('estado'));
  const texto = params.get('texto') ?? '';
  const fechaDesde = params.get('desde') ?? '';
  const fechaHasta = params.get('hasta') ?? '';
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const orden = OPCIONES_ORDEN_PEDIDOS.find((o) => o.valor === params.get('orden'))?.valor ?? 'Fecha|DESC';
  const [ordenarPor, direccion] = orden.split('|') as [Filtros['ordenarPor'], Filtros['direccion']];

  const consulta = usePedidosGestion({
    estado,
    texto: texto || undefined,
    fechaDesde: fechaDesde || undefined,
    fechaHasta: fechaHasta || undefined,
    ordenarPor,
    direccion,
    pagina,
    registrosPorPagina: TAMANO_PAGINA,
  });

  return (
    <main className="mx-auto max-w-7xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Pedidos</h1>

      <FiltrosPedidosGestion
        key={`${texto}|${fechaDesde}|${fechaHasta}`}
        estado={estado}
        texto={texto}
        fechaDesde={fechaDesde}
        fechaHasta={fechaHasta}
        orden={orden}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando pedidos..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="No hay pedidos" descripcion="Prueba con otros filtros." />
      ) : (
        <>
          <p className="text-sm text-gray-600">
            {consulta.data.totalRegistros} {consulta.data.totalRegistros === 1 ? 'pedido' : 'pedidos'}
          </p>

          <div className={`tarjeta overflow-x-auto transition-opacity duration-150 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="tabla">
              <thead>
                <tr>
                  <th className="px-4 py-3">Pedido</th>
                  <th className="px-4 py-3">Cliente</th>
                  <th className="px-4 py-3">Fecha</th>
                  <th className="px-4 py-3">Estado</th>
                  <th className="px-4 py-3 text-right">Total</th>
                  <th className="px-4 py-3 text-right">Devuelto</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((p) => (
                  <tr key={p.idPedido}>
                    <td className="px-4 py-3 font-medium">{p.numeroPedido}</td>
                    <td className="px-4 py-3">
                      <p>{p.nombreCliente}</p>
                      <p className="text-xs text-gray-500">{p.correoCliente}</p>
                    </td>
                    <td className="whitespace-nowrap px-4 py-3">{formatearFechaHora(p.fechaCreacion)}</td>
                    <td className="px-4 py-3">
                      <InsigniaEstado estado={p.estado} />
                    </td>
                    <td className="px-4 py-3 text-right">{formatearMoneda(p.total)}</td>
                    <td className="px-4 py-3 text-right">{p.devuelto > 0 ? formatearMoneda(p.devuelto) : '—'}</td>
                    <td className="px-4 py-3 text-right">
                      <Link to={`/gestion/pedidos/${p.idPedido}`} className="font-medium text-marca-700 hover:underline">
                        Ver
                      </Link>
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
    </main>
  );
}