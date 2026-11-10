import type { AtributoCatalogo, AtributoFormulario } from '../tipos/catalogoAdmin';

interface Propiedades {
  valor: AtributoFormulario[];
  alCambiar: (valor: AtributoFormulario[]) => void;
  disponibles: AtributoCatalogo[];
  errores: Record<string, string>;
  prefijo: string;
}

const claseCampo = 'control';

export function EditorAtributos({ valor, alCambiar, disponibles, errores, prefijo }: Propiedades) {
  const actualizar = (indice: number, cambios: Partial<AtributoFormulario>) =>
    alCambiar(valor.map((a, i) => (i === indice ? { ...a, ...cambios } : a)));

  return (
    <div className="space-y-2">
      {valor.map((a, i) => {
        const errorAtributo = errores[`${prefijo}.${i}.atributo`];
        const errorValor = errores[`${prefijo}.${i}.valor`];

        return (
          <div key={i} className="flex flex-wrap items-start gap-2">
            <div>
              <select
                aria-label={`Atributo ${i + 1}`}
                value={a.atributo}
                onChange={(e) => actualizar(i, { atributo: e.target.value })}
                className={`${claseCampo} ${errorAtributo ? 'border-red-500 hover:border-red-500' : ''}`}
              >
                <option value="">Atributo...</option>
                {disponibles.map((d) => (
                  <option key={d.idAtributo} value={d.nombre}>
                    {d.nombre}
                  </option>
                ))}
              </select>
              {errorAtributo && <p className="mt-1 text-xs text-red-600">{errorAtributo}</p>}
            </div>

            <div>
              <input
                aria-label={`Valor del atributo ${i + 1}`}
                placeholder="Valor (ej.: Rojo)"
                maxLength={50}
                value={a.valor}
                onChange={(e) => actualizar(i, { valor: e.target.value })}
                className={`${claseCampo} ${errorValor ? 'border-red-500 hover:border-red-500' : ''}`}
              />
              {errorValor && <p className="mt-1 text-xs text-red-600">{errorValor}</p>}
            </div>

            <button
              type="button"
              aria-label={`Quitar atributo ${i + 1}`}
              onClick={() => alCambiar(valor.filter((_, k) => k !== i))}
              className="min-h-11 rounded-control px-3 text-sm font-medium text-red-700 hover:bg-red-50 sm:min-h-10"
            >
              Quitar
            </button>
          </div>
        );
      })}

      {errores[prefijo] && (
        <p role="alert" className="text-xs text-red-600">
          {errores[prefijo]}
        </p>
      )}

      <button
        type="button"
        onClick={() => alCambiar([...valor, { atributo: '', valor: '' }])}
        className="inline-flex min-h-10 items-center text-sm font-medium text-marca-700 hover:underline"
      >
        + Agregar atributo
      </button>
    </div>
  );
}