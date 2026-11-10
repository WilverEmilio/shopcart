import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { Modal } from '../../../componentes/Modal';
import { erroresDeZod } from '../../../utilidades/formularios';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda } from '../../../utilidades/formato';
import { precioFormEsquema } from '../esquemas/catalogoAdminEsquema';
import { useAccionesVariante } from '../hooks/useCatalogoAdmin';

interface VariantePrecio {
  idVariante: number;
  sku: string;
  precio: number;
}

interface Propiedades {
  abierto: boolean;
  variante: VariantePrecio | null;
  alCerrar: () => void;
  alGuardado: (mensaje: string) => void;
}

function FormularioPrecio({ variante, alCerrar, alGuardado }: Omit<Propiedades, 'abierto' | 'variante'> & { variante: VariantePrecio }) {
  const { cambiarPrecio } = useAccionesVariante();
  const [precio, setPrecio] = useState(String(variante.precio));
  const [errores, setErrores] = useState<Record<string, string>>({});

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();

    const resultado = precioFormEsquema.safeParse({ precio });
    if (!resultado.success) {
      setErrores(erroresDeZod(resultado.error));
      return;
    }
    setErrores({});

    cambiarPrecio.mutate(
      { idVariante: variante.idVariante, precio: resultado.data.precio },
      {
        onSuccess: () => {
          alGuardado(`Precio de ${variante.sku} actualizado a ${formatearMoneda(resultado.data.precio)}.`);
          alCerrar();
        },
      }
    );
  };

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <p className="text-sm text-slate-600">
        SKU <strong>{variante.sku}</strong> · precio actual {formatearMoneda(variante.precio)}
      </p>

      <CampoFormulario etiqueta="Nuevo precio (Q, IVA incluido)" inputMode="decimal" value={precio} onChange={(e) => setPrecio(e.target.value)} error={errores.precio} />

      <p className="text-xs text-slate-500">
        El cambio solo afecta a compras futuras: los pedidos ya realizados conservan el precio con el que se compraron.
      </p>

      {cambiarPrecio.isError && (
        <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {normalizarError(cambiarPrecio.error).mensaje}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={cambiarPrecio.isPending}>
          Cancelar
        </Boton>
        <Boton type="submit" cargando={cambiarPrecio.isPending}>
          Cambiar precio
        </Boton>
      </div>
    </form>
  );
}

export function DialogoPrecio({ abierto, variante, alCerrar, alGuardado }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo="Cambiar precio" alCerrar={alCerrar}>
      {variante && <FormularioPrecio variante={variante} alCerrar={alCerrar} alGuardado={alGuardado} />}
    </Modal>
  );
}