import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { ESTADOS_PEDIDO, ETIQUETA_ESTADO, OPCIONES_ORDEN_PEDIDOS } from '../constante';
import type { EstadoPedido } from '../tipos/pedido';



interface Propiedades {
  estado: EstadoPedido | undefined;
  texto: string;
  fechaDesde: string;
  fechaHasta: string;
  orden: string;
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

const claseSelect =
  'control';

export function FiltrosPedidosGestion({ estado, texto, fechaDesde, fechaHasta, orden, alCambiar, alLimpiar }: Propiedades) {
  const [textoLocal, setTextoLocal] = useState(texto);
  const [desde, setDesde] = useState(fechaDesde);
  const [hasta, setHasta] = useState(fechaHasta);
  const [errorFechas, setErrorFechas] = useState<string | null>(null);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    if (desde && hasta && desde > hasta) {
      setErrorFechas('La fecha inicial no puede ser posterior a la final.');
      return;
    }
    setErrorFechas(null);
    alCambiar({ texto: textoLocal.trim() || undefined, desde: desde || undefined, hasta: hasta || undefined });
  };

  const limpiar = () => {
    setTextoLocal('');
    setDesde('');
    setHasta('');
    setErrorFechas(null);
    alLimpiar();
  };

  return (
    <form onSubmit={aplicar} noValidate className="tarjeta space-y-4 p-4">
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <CampoFormulario
          etiqueta="Buscar"
          type="search"
          placeholder="N.º de pedido, cliente o correo"
          maxLength={100}
          value={textoLocal}
          onChange={(e) => setTextoLocal(e.target.value)}
        />

        <div>
          <label htmlFor="filtro-estado" className="mb-1.5 block text-sm font-medium text-gray-700">
            Estado
          </label>
          <select
            id="filtro-estado"
            className={claseSelect}
            value={estado ?? ''}
            onChange={(e) => alCambiar({ estado: e.target.value || undefined })}
          >
            <option value="">Todos</option>
            {ESTADOS_PEDIDO.map((e) => (
              <option key={e} value={e}>
                {ETIQUETA_ESTADO[e]}
              </option>
            ))}
          </select>
        </div>

        <CampoFormulario etiqueta="Desde" type="date" value={desde} onChange={(e) => setDesde(e.target.value)} />
        <CampoFormulario etiqueta="Hasta" type="date" value={hasta} onChange={(e) => setHasta(e.target.value)} error={errorFechas ?? undefined} />
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="w-56">
          <label htmlFor="filtro-orden" className="mb-1.5 block text-sm font-medium text-gray-700">
            Ordenar por
          </label>
          <select id="filtro-orden" className={claseSelect} value={orden} onChange={(e) => alCambiar({ orden: e.target.value })}>
            {OPCIONES_ORDEN_PEDIDOS.map((o) => (
              <option key={o.valor} value={o.valor}>
                {o.etiqueta}
              </option>
            ))}
          </select>
        </div>
        <Boton type="submit">Aplicar</Boton>
        <Boton variante="secundario" onClick={limpiar}>
          Limpiar filtros
        </Boton>
      </div>
    </form>
  );
}