import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { formatearFechaHora, formatearMoneda } from '../../../utilidades/formato';
import { useCarritosAbandonados } from '../hooks/useReportes';
import type { FiltrosAbandonados } from '../tipos/reportes';

export const OPCIONES_ORDEN_ABANDONADOS = [
  { valor: 'HorasInactivo|DESC', etiqueta: 'Más tiempo inactivos' },
  { valor: 'HorasInactivo|ASC', etiqueta: 'Más recientes' },
  { valor: 'Valor|DESC', etiqueta: 'Mayor valor' },
  { valor: 'Unidades|DESC', etiqueta: 'Más unidades' },
] as const;

interface Propiedades {
  filtros: FiltrosAbandonados;
  orden: string;
  alCambiarOrden: (valor: string) => void;
  alCambiarPagina: (pagina: number) => void;
}

const formatearInactividad = (horas: number): string =>
  horas < 48 ? `${horas} h` : `${Math.floor(horas / 24)} días`;

export function TablaCarritosAbandonados({ filtros, orden, alCambiarOrden, alCambiarPagina }: Propiedades) {
  const consulta = useCarritosAbandonados(filtros);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <p className="text-sm text-gray-600">
          {consulta.data
            ? `${consulta.data.totalRegistros} carritos con productos y sin actividad · valor total ${formatearMoneda(consulta.data.valorTotal)}`
            : 'Carritos con productos y sin actividad reciente'}
        </p>

        <div>
          <label htmlFor="ab-orden" className="mb-1 block text-sm font-medium text-gray-700">
            Ordenar por
          </label>
          <select
            id="ab-orden"
            value={orden}
            onChange={(e) => alCambiarOrden(e.target.value)}
            className="rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
          >
            {OPCIONES_ORDEN_ABANDONADOS.map((o) => (
              <option key={o.valor} value={o.valor}>
                {o.etiqueta}
              </option>
            ))}
          </select>
        </div>
      </div>

      {consulta.isPending ? (
        <EstadoCarga />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="No hay carritos abandonados" descripcion="Todos los carritos activos tienen movimiento reciente." />
      ) : (
        <>
          <div className={`overflow-x-auto rounded-lg border border-gray-200 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">Cliente</th>
                  <th className="px-4 py-3 text-right">Líneas</th>
                  <th className="px-4 py-3 text-right">Unidades</th>
                  <th className="px-4 py-3 text-right">Valor</th>
                  <th className="px-4 py-3">Última actividad</th>
                  <th className="px-4 py-3 text-right">Inactivo</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((c) => (
                  <tr key={c.idCarrito} className="hover:bg-gray-50">
                    <td className="px-4 py-3">{c.esInvitado ? <span className="text-gray-500">Invitado</span> : c.cliente}</td>
                    <td className="px-4 py-3 text-right">{c.lineas}</td>
                    <td className="px-4 py-3 text-right">{c.unidades}</td>
                    <td className="px-4 py-3 text-right font-medium">{formatearMoneda(c.valor)}</td>
                    <td className="whitespace-nowrap px-4 py-3">{formatearFechaHora(c.fechaActualizacion)}</td>
                    <td className="px-4 py-3 text-right">{formatearInactividad(c.horasInactivo)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Paginador
            pagina={consulta.data.pagina}
            tamanoPagina={consulta.data.tamanoPagina}
            totalRegistros={consulta.data.totalRegistros}
            alCambiar={alCambiarPagina}
          />
        </>
      )}
    </div>
  );
}