import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { ETIQUETA_MOVIMIENTO, TIPOS_MOVIMIENTO } from '../constante';

interface Propiedades {
  texto: string;
  tipo: string;
  fechaDesde: string;
  fechaHasta: string;
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

export function FiltrosKardex({ texto, tipo, fechaDesde, fechaHasta, alCambiar, alLimpiar }: Propiedades) {
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
          placeholder="SKU, producto o motivo"
          maxLength={100}
          value={textoLocal}
          onChange={(e) => setTextoLocal(e.target.value)}
        />

        <div>
          <label htmlFor="kardex-tipo" className="mb-1.5 block text-sm font-medium text-gray-700">
            Tipo de movimiento
          </label>
          <select
            id="kardex-tipo"
            value={tipo}
            onChange={(e) => alCambiar({ tipo: e.target.value || undefined })}
            className="control"
          >
            <option value="">Todos</option>
            {TIPOS_MOVIMIENTO.map((t) => (
              <option key={t} value={t}>
                {ETIQUETA_MOVIMIENTO[t]}
              </option>
            ))}
          </select>
        </div>

        <CampoFormulario etiqueta="Desde" type="date" value={desde} onChange={(e) => setDesde(e.target.value)} />
        <CampoFormulario etiqueta="Hasta" type="date" value={hasta} onChange={(e) => setHasta(e.target.value)} error={errorFechas ?? undefined} />
      </div>

      <div className="flex gap-3">
        <Boton type="submit">Aplicar</Boton>
        <Boton variante="secundario" onClick={limpiar}>
          Limpiar filtros
        </Boton>
      </div>
    </form>
  );
}