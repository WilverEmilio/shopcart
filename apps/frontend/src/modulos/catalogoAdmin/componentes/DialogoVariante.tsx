import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { Modal } from '../../../componentes/Modal';
import { erroresPorCampo, normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import { varianteEdicionFormEsquema, varianteFormEsquema } from '../esquemas/catalogoAdminEsquema';
import { useAccionesVariante } from '../hooks/useCatalogoAdmin';
import type { AtributoCatalogo, VarianteFormulario } from '../tipos/catalogoAdmin';
import { CamposVariante } from './CamposVariante';

export interface VarianteEnEdicion {
  idVariante: number;
  sku: string;
  atributos: { atributo: string; valor: string }[];
}

interface Propiedades {
  abierto: boolean;
  idProducto: number;
  /** null = variante nueva */
  variante: VarianteEnEdicion | null;
  atributosDisponibles: AtributoCatalogo[];
  alCerrar: () => void;
  alGuardada: (mensaje: string) => void;
}

function FormularioVariante({ idProducto, variante, atributosDisponibles, alCerrar, alGuardada }: Omit<Propiedades, 'abierto'>) {
  const { crear, actualizar } = useAccionesVariante();

  const [valor, setValor] = useState<VarianteFormulario>({
    sku: variante?.sku ?? '',
    precio: '',
    atributos: variante?.atributos ?? [],
  });
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const pendiente = crear.isPending || actualizar.isPending;

  const alError = (error: unknown) => {
    const porCampo = erroresPorCampo(error);
    if (Object.keys(porCampo).length > 0) setErrores(porCampo);
    else setErrorGeneral(normalizarError(error).mensaje);
  };

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    setErrorGeneral(null);

    const alExito = (mensaje: string) => () => {
      alGuardada(mensaje);
      alCerrar();
    };

    if (variante) {
      const resultado = varianteEdicionFormEsquema.safeParse(valor);
      if (!resultado.success) {
        setErrores(erroresDeZod(resultado.error));
        return;
      }
      setErrores({});
      actualizar.mutate(
        { idVariante: variante.idVariante, datos: resultado.data },
        { onSuccess: alExito('Variante actualizada.'), onError: alError }
      );
    } else {
      const resultado = varianteFormEsquema.safeParse(valor);
      if (!resultado.success) {
        setErrores(erroresDeZod(resultado.error));
        return;
      }
      setErrores({});
      crear.mutate({ idProducto, datos: resultado.data }, { onSuccess: alExito('Variante creada.'), onError: alError });
    }
  };

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <CamposVariante
        valor={valor}
        alCambiar={setValor}
        mostrarPrecio={variante === null}
        atributosDisponibles={atributosDisponibles}
        errores={errores}
        prefijo=""
      />

      {variante && (
        <p className="text-xs text-slate-500">El precio se cambia aparte, con la acción «Precio» de la tabla.</p>
      )}

      {errorGeneral && (
        <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {errorGeneral}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={pendiente}>
          Cancelar
        </Boton>
        <Boton type="submit" cargando={pendiente}>
          {variante ? 'Guardar cambios' : 'Crear variante'}
        </Boton>
      </div>
    </form>
  );
}

export function DialogoVariante({ abierto, alCerrar, ...resto }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo={resto.variante ? 'Editar variante' : 'Nueva variante'} alCerrar={alCerrar}>
      <FormularioVariante alCerrar={alCerrar} {...resto} />
    </Modal>
  );
}