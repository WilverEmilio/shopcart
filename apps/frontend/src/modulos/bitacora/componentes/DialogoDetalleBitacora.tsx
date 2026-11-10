import { Boton } from '../../../componentes/Boton';
import { Modal } from '../../../componentes/Modal';
import { formatearFechaHora } from '../../../utilidades/formato';
import type { RegistroBitacora } from '../tipos/bitacora';

interface Propiedades {
  registro: RegistroBitacora | null;
  alCerrar: () => void;
}

const aObjeto = (valor: unknown): Record<string, unknown> =>
  valor && typeof valor === 'object' && !Array.isArray(valor) ? (valor as Record<string, unknown>) : {};

const mostrar = (valor: unknown): string => {
  if (valor === null || valor === undefined) return '—';
  if (typeof valor === 'object') return JSON.stringify(valor);
  return String(valor);
};

function Contenido({ registro, alCerrar }: { registro: RegistroBitacora; alCerrar: () => void }) {
  const antes = aObjeto(registro.valorAnterior);
  const despues = aObjeto(registro.valorNuevo);
  const claves = [...new Set([...Object.keys(antes), ...Object.keys(despues)])];

  const sinEstructura = claves.length === 0;

  return (
    <div className="space-y-4">
      <dl className="grid gap-x-4 gap-y-1 text-sm sm:grid-cols-2">
        <div>
          <dt className="inline text-gray-500">Fecha: </dt>
          <dd className="inline">{formatearFechaHora(registro.fecha)}</dd>
        </div>
        <div>
          <dt className="inline text-gray-500">Usuario: </dt>
          <dd className="inline">{registro.correoUsuario ?? 'Sistema'}</dd>
        </div>
        <div>
          <dt className="inline text-gray-500">Módulo: </dt>
          <dd className="inline">{registro.modulo}</dd>
        </div>
        <div>
          <dt className="inline text-gray-500">Entidad: </dt>
          <dd className="inline">
            {registro.entidad} {registro.idEntidad !== null && `#${registro.idEntidad}`}
          </dd>
        </div>
      </dl>

      {sinEstructura ? (
        <div className="grid gap-3 text-sm sm:grid-cols-2">
          <div>
            <p className="mb-1 font-medium text-gray-700">Valor anterior</p>
            <pre className="overflow-x-auto rounded-md bg-gray-50 p-3 text-xs">{mostrar(registro.valorAnterior)}</pre>
          </div>
          <div>
            <p className="mb-1 font-medium text-gray-700">Valor nuevo</p>
            <pre className="overflow-x-auto rounded-md bg-gray-50 p-3 text-xs">{mostrar(registro.valorNuevo)}</pre>
          </div>
        </div>
      ) : (
        <div className="overflow-x-auto rounded-lg border border-gray-200">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 text-xs uppercase text-gray-500">
              <tr>
                <th className="px-3 py-2">Campo</th>
                <th className="px-3 py-2">Antes</th>
                <th className="px-3 py-2">Después</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {claves.map((clave) => {
                const cambio = JSON.stringify(antes[clave]) !== JSON.stringify(despues[clave]);
                return (
                  <tr key={clave} className={cambio ? 'bg-amber-50' : ''}>
                    <td className="px-3 py-2 font-mono text-xs">{clave}</td>
                    <td className="break-all px-3 py-2 text-gray-600">{mostrar(antes[clave])}</td>
                    <td className={`break-all px-3 py-2 ${cambio ? 'font-medium' : 'text-gray-600'}`}>{mostrar(despues[clave])}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      <div className="flex justify-end">
        <Boton variante="secundario" onClick={alCerrar}>
          Cerrar
        </Boton>
      </div>
    </div>
  );
}

export function DialogoDetalleBitacora({ registro, alCerrar }: Propiedades) {
  return (
    <Modal abierto={registro !== null} titulo="Detalle del registro" ancho="amplio" alCerrar={alCerrar}>
      {registro && <Contenido registro={registro} alCerrar={alCerrar} />}
    </Modal>
  );
}