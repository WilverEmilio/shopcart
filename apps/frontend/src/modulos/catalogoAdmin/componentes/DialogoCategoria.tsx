import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { Modal } from '../../../componentes/Modal';
import { erroresPorCampo, normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import { categoriaFormEsquema } from '../esquemas/catalogoAdminEsquema';
import { useAccionesCategoria } from '../hooks/useCatalogoAdmin';
import type { CategoriaAdmin } from '../tipos/catalogoAdmin';

interface Propiedades {
  abierto: boolean;
  /** null = categoría nueva */
  categoria: CategoriaAdmin | null;
  alCerrar: () => void;
  alGuardada: (mensaje: string) => void;
}

function FormularioCategoria({ categoria, alCerrar, alGuardada }: Omit<Propiedades, 'abierto'>) {
  const { crear, actualizar } = useAccionesCategoria();

  const [datos, setDatos] = useState({ nombre: categoria?.nombre ?? '', descripcion: categoria?.descripcion ?? '' });
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

    const resultado = categoriaFormEsquema.safeParse(datos);
    if (!resultado.success) {
      setErrores(erroresDeZod(resultado.error));
      return;
    }
    setErrores({});

    const payload = { nombre: resultado.data.nombre, descripcion: resultado.data.descripcion || null };
    const alExito = (mensaje: string) => () => {
      alGuardada(mensaje);
      alCerrar();
    };

    if (categoria) {
      actualizar.mutate(
        { idCategoria: categoria.idCategoria, datos: payload },
        { onSuccess: alExito(`Categoría «${payload.nombre}» actualizada.`), onError: alError }
      );
    } else {
      crear.mutate(payload, { onSuccess: alExito(`Categoría «${payload.nombre}» creada.`), onError: alError });
    }
  };

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <CampoFormulario
        etiqueta="Nombre"
        maxLength={100}
        value={datos.nombre}
        onChange={(e) => setDatos({ ...datos, nombre: e.target.value })}
        error={errores.nombre}
      />
      <CampoFormulario
        etiqueta="Descripción (opcional)"
        maxLength={255}
        value={datos.descripcion}
        onChange={(e) => setDatos({ ...datos, descripcion: e.target.value })}
        error={errores.descripcion}
      />

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
          {categoria ? 'Guardar cambios' : 'Crear categoría'}
        </Boton>
      </div>
    </form>
  );
}

export function DialogoCategoria({ abierto, categoria, alCerrar, alGuardada }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo={categoria ? 'Editar categoría' : 'Nueva categoría'} alCerrar={alCerrar}>
      <FormularioCategoria categoria={categoria} alCerrar={alCerrar} alGuardada={alGuardada} />
    </Modal>
  );
}