import { CampoFormulario } from '../../../componentes/CampoFormulario';
import type { AtributoCatalogo, VarianteFormulario } from '../tipos/catalogoAdmin';
import { EditorAtributos } from './EditorAtributos';

interface Propiedades {
  valor: VarianteFormulario;
  alCambiar: (valor: VarianteFormulario) => void;
  mostrarPrecio: boolean;
  atributosDisponibles: AtributoCatalogo[];
  errores: Record<string, string>;
  prefijo: string;
}

export function CamposVariante({ valor, alCambiar, mostrarPrecio, atributosDisponibles, errores, prefijo }: Propiedades) {
  const clave = (campo: string) => (prefijo ? `${prefijo}.${campo}` : campo);

  return (
    <div className="space-y-4">
      <div className={`grid gap-4 ${mostrarPrecio ? 'sm:grid-cols-2' : ''}`}>
        <CampoFormulario
          etiqueta="SKU"
          maxLength={50}
          value={valor.sku}
          onChange={(e) => alCambiar({ ...valor, sku: e.target.value })}
          error={errores[clave('sku')]}
        />
        {mostrarPrecio && (
          <CampoFormulario
            etiqueta="Precio (Q, IVA incluido)"
            inputMode="decimal"
            value={valor.precio}
            onChange={(e) => alCambiar({ ...valor, precio: e.target.value })}
            error={errores[clave('precio')]}
          />
        )}
      </div>

      <div>
        <p className="mb-2 text-sm font-medium text-gray-700">Atributos (talla, color...)</p>
        <EditorAtributos
          valor={valor.atributos}
          alCambiar={(atributos) => alCambiar({ ...valor, atributos })}
          disponibles={atributosDisponibles}
          errores={errores}
          prefijo={clave('atributos')}
        />
      </div>
    </div>
  );
}