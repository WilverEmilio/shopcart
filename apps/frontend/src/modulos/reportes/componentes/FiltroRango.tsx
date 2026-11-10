import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { diasEntre, PRESETS_RANGO, rangoUltimosDias } from '../rangos';
import type { RangoFechas } from '../tipos/reportes';

interface Propiedades {
  rango: RangoFechas;
  alCambiar: (cambios: Record<string, string | undefined>) => void;
}

export function FiltroRango({ rango, alCambiar }: Propiedades) {
  const [desde, setDesde] = useState(rango.fechaDesde);
  const [hasta, setHasta] = useState(rango.fechaHasta);
  const [error, setError] = useState<string | null>(null);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();

    if (!desde || !hasta) {
      setError('Indica las dos fechas.');
      return;
    }
    if (desde > hasta) {
      setError('La fecha inicial no puede ser posterior a la final.');
      return;
    }
    if (diasEntre(desde, hasta) > 730) {
      setError('El máximo es de 2 años.');
      return;
    }

    setError(null);
    alCambiar({ desde, hasta });
  };

  return (
    <form onSubmit={aplicar} noValidate className="flex flex-wrap items-end gap-3 rounded-lg border border-gray-200 bg-white p-4">
      <div className="flex flex-wrap gap-2">
        {PRESETS_RANGO.map((p) => {
          const rangoPreset = rangoUltimosDias(p.dias);
          const activo = rangoPreset.fechaDesde === rango.fechaDesde && rangoPreset.fechaHasta === rango.fechaHasta;
          return (
            <button
              key={p.dias}
              type="button"
              aria-pressed={activo}
              onClick={() => {
                setDesde(rangoPreset.fechaDesde);
                setHasta(rangoPreset.fechaHasta);
                setError(null);
                alCambiar({ desde: rangoPreset.fechaDesde, hasta: rangoPreset.fechaHasta });
              }}
              className={`rounded-md border px-3 py-2 text-sm ${
                activo ? 'border-indigo-600 bg-indigo-50 text-indigo-700' : 'border-gray-300 hover:bg-gray-100'
              }`}
            >
              {p.etiqueta}
            </button>
          );
        })}
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <CampoFormulario etiqueta="Desde" type="date" value={desde} onChange={(e) => setDesde(e.target.value)} />
        <CampoFormulario etiqueta="Hasta" type="date" value={hasta} onChange={(e) => setHasta(e.target.value)} error={error ?? undefined} />
        <Boton type="submit">Aplicar rango</Boton>
      </div>
    </form>
  );
}