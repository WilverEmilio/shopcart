import { Link } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { NavegacionInventario } from '../componentes/NavegacionInventario';
import { useConciliacion } from '../hooks/useInventario';

const TAMANO_PAGINA = 50;

export function PaginaConciliacion() {
  const { params, actualizar } = useParametrosUrl();

  const soloDiferencias = params.get('todas') !== 'true';
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useConciliacion({ soloDiferencias, pagina, registrosPorPagina: TAMANO_PAGINA });

  const claseDiferencia = (n: number) => (n === 0 ? 'text-gray-400' : 'font-semibold text-red-600');

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <h1 className="text-2xl font-semibold">Inventario</h1>
      <NavegacionInventario />

      <p className="text-sm text-gray-500">
        Compara la existencia física de cada variante con la suma de sus movimientos del kardex, y las unidades
        reservadas con las reservas activas. Ambas deben coincidir.
      </p>

      <label className="flex items-center gap-2 text-sm text-gray-700">
        <input
          type="checkbox"
          checked={!soloDiferencias}
          onChange={(e) => actualizar({ todas: e.target.checked ? 'true' : undefined })}
        />
        Mostrar también las variantes que cuadran
      </label>

      {consulta.isPending ? (
        <EstadoCarga mensaje="Calculando conciliación..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <p role="status" className="rounded-md bg-green-50 p-6 text-center text-green-800">
          Todo cuadra: la existencia de todas las variantes coincide con el kardex.
        </p>
      ) : (
        <>
          <p className="text-sm text-gray-500">{consulta.data.totalRegistros} variantes</p>

          <div className={`overflow-x-auto rounded-lg border border-gray-200 bg-white ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">SKU</th>
                  <th className="px-4 py-3 text-right">Física</th>
                  <th className="px-4 py-3 text-right">Suma kardex</th>
                  <th className="px-4 py-3 text-right">Diferencia</th>
                  <th className="px-4 py-3 text-right">Reservada</th>
                  <th className="px-4 py-3 text-right">Reservas activas</th>
                  <th className="px-4 py-3 text-right">Diferencia</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((f) => (
                  <tr key={f.idVariante} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-mono text-xs">{f.sku}</td>
                    <td className="px-4 py-3 text-right">{f.existenciaFisica}</td>
                    <td className="px-4 py-3 text-right">{f.sumaKardex}</td>
                    <td className={`px-4 py-3 text-right ${claseDiferencia(f.diferenciaFisica)}`}>{f.diferenciaFisica}</td>
                    <td className="px-4 py-3 text-right">{f.existenciaReservada}</td>
                    <td className="px-4 py-3 text-right">{f.sumaReservasActivas}</td>
                    <td className={`px-4 py-3 text-right ${claseDiferencia(f.diferenciaReservada)}`}>{f.diferenciaReservada}</td>
                    <td className="px-4 py-3 text-right">
                      <Link to={`/gestion/inventario/kardex?variante=${f.idVariante}`} className="text-indigo-600 hover:underline">
                        Kardex
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
            alCambiar={(p) => actualizar({ pagina: String(p) })}
          />
        </>
      )}
    </main>
  );
}