import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { formatearFechaHora } from '../../../utilidades/formato';
import { DialogoDetalleBitacora } from '../componentes/DialogoDetalleBitacora';
import { useBitacora } from '../hooks/useBitacora';
import { MODULOS_BITACORA, type RegistroBitacora } from '../tipos/bitacora';

const CLASE_ACCION: Record<string, string> = {
  CREAR: 'bg-green-100 text-green-800',
  MODIFICAR: 'bg-blue-100 text-blue-800',
  CAMBIO_ESTADO: 'bg-indigo-100 text-indigo-800',
  DESACTIVAR: 'bg-amber-100 text-amber-800',
  ELIMINAR: 'bg-red-100 text-red-800',
};

const ETIQUETA_ACCION: Record<string, string> = {
  CREAR: 'Crear',
  MODIFICAR: 'Modificar',
  CAMBIO_ESTADO: 'Cambio de estado',
  DESACTIVAR: 'Desactivar',
  ELIMINAR: 'Eliminar',
};

interface PropiedadesFiltros {
  modulo: string;
  fechaDesde: string;
  fechaHasta: string;
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

function Filtros({ modulo, fechaDesde, fechaHasta, alCambiar, alLimpiar }: PropiedadesFiltros) {
  const [desde, setDesde] = useState(fechaDesde);
  const [hasta, setHasta] = useState(fechaHasta);
  const [error, setError] = useState<string | null>(null);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    if (desde && hasta && desde > hasta) {
      setError('La fecha inicial no puede ser posterior a la final.');
      return;
    }
    setError(null);
    alCambiar({ desde: desde || undefined, hasta: hasta || undefined });
  };

  return (
    <form onSubmit={aplicar} noValidate className="grid gap-4 rounded-lg border border-gray-200 bg-white p-4 sm:grid-cols-2 lg:grid-cols-4 lg:items-end">
      <div>
        <label htmlFor="bit-modulo" className="mb-1 block text-sm font-medium text-gray-700">
          Módulo
        </label>
        <select
          id="bit-modulo"
          value={modulo}
          onChange={(e) => alCambiar({ modulo: e.target.value || undefined })}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">Todos</option>
          {MODULOS_BITACORA.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
      </div>

      <CampoFormulario etiqueta="Desde" type="date" value={desde} onChange={(e) => setDesde(e.target.value)} />
      <CampoFormulario etiqueta="Hasta" type="date" value={hasta} onChange={(e) => setHasta(e.target.value)} error={error ?? undefined} />

      <div className="flex gap-2">
        <Boton type="submit">Aplicar</Boton>
        <Boton
          variante="secundario"
          onClick={() => {
            setDesde('');
            setHasta('');
            setError(null);
            alLimpiar();
          }}
        >
          Limpiar
        </Boton>
      </div>
    </form>
  );
}

export function PaginaBitacora() {
  const { params, actualizar, limpiar } = useParametrosUrl();

  const modulo = MODULOS_BITACORA.find((m) => m === params.get('modulo'));
  const fechaDesde = params.get('desde') ?? '';
  const fechaHasta = params.get('hasta') ?? '';
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useBitacora({
    modulo,
    fechaDesde: fechaDesde || undefined,
    fechaHasta: fechaHasta || undefined,
    pagina,
    registrosPorPagina: 20,
  });

  const [detalle, setDetalle] = useState<RegistroBitacora | null>(null);

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-semibold">Bitácora</h1>
        <p className="text-sm text-gray-500">
          Registro de auditoría de solo lectura: no puede modificarse ni eliminarse.
        </p>
      </div>

      <Filtros
        key={`${fechaDesde}|${fechaHasta}`}
        modulo={modulo ?? ''}
        fechaDesde={fechaDesde}
        fechaHasta={fechaHasta}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando bitácora..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="Sin registros" descripcion="No hay movimientos con esos filtros." />
      ) : (
        <>
          <p className="text-sm text-gray-500">{consulta.data.totalRegistros} registros</p>

          <div className={`overflow-x-auto rounded-lg border border-gray-200 bg-white ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">Fecha</th>
                  <th className="px-4 py-3">Módulo</th>
                  <th className="px-4 py-3">Entidad</th>
                  <th className="px-4 py-3">Acción</th>
                  <th className="px-4 py-3">Usuario</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((r) => (
                  <tr key={String(r.idBitacora)} className="hover:bg-gray-50">
                    <td className="whitespace-nowrap px-4 py-3">{formatearFechaHora(r.fecha)}</td>
                    <td className="px-4 py-3">{r.modulo}</td>
                    <td className="px-4 py-3">
                      {r.entidad}
                      {r.idEntidad !== null && <span className="text-gray-400"> #{r.idEntidad}</span>}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${CLASE_ACCION[r.accios] ?? 'bg-gray-200 text-gray-700'}`}>
                        {ETIQUETA_ACCION[r.accios] ?? r.accios}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-600">{r.correoUsuario ?? 'Sistema'}</td>
                    <td className="px-4 py-3 text-right">
                      <button type="button" onClick={() => setDetalle(r)} className="text-indigo-600 hover:underline">
                        Ver detalle
                      </button>
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

      <DialogoDetalleBitacora registro={detalle} alCerrar={() => setDetalle(null)} />
    </main>
  );
}