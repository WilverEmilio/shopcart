import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { aplicarErrorServidor } from '../../../utilidades/formularios';
import { DEPARTAMENTOS_GUATEMALA } from '../constantes';
import { direccionEsquema, type DatosFormularioDireccion } from '../esquemas/direccionEsquema';
import { useCrearDireccion } from '../hooks/useDirecciones';

interface Propiedades {
  alGuardar: (idDireccion: number) => void;
  alCancelar?: () => void;
}

export function FormularioDireccion({ alGuardar, alCancelar }: Propiedades) {
  const usuario = useSesionEstado((e) => e.usuario);
  const crear = useCrearDireccion();
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<DatosFormularioDireccion>({
    resolver: zodResolver(direccionEsquema),
    defaultValues: {
      nombreDestinatario: usuario ? `${usuario.nombres} ${usuario.apellidos}` : '',
      telefono: '',
      departamento: '',
      municipio: '',
      direccion: '',
      referencia: '',
      esPredeterminada: false,
    },
  });

  const alEnviar = handleSubmit(async (datos) => {
    setErrorGeneral(null);
    try {
      const idDireccion = await crear.mutateAsync({ ...datos, referencia: datos.referencia || null });
      alGuardar(idDireccion);
    } catch (error) {
      setErrorGeneral(
        aplicarErrorServidor(error, setError, [
          'nombreDestinatario', 'telefono', 'departamento', 'municipio', 'direccion', 'referencia',
        ])
      );
    }
  });

  return (
    <form onSubmit={alEnviar} noValidate className="space-y-4 rounded-lg border border-gray-200 bg-white p-4">
      <h3 className="font-medium">Nueva dirección de entrega</h3>

      {errorGeneral && (
        <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {errorGeneral}
        </p>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <CampoFormulario etiqueta="Nombre de quien recibe" error={errors.nombreDestinatario?.message} {...register('nombreDestinatario')} />
        <CampoFormulario etiqueta="Teléfono" type="tel" autoComplete="tel" error={errors.telefono?.message} {...register('telefono')} />
        <CampoFormulario etiqueta="Departamento" list="departamentos-gt" error={errors.departamento?.message} {...register('departamento')} />
        <CampoFormulario etiqueta="Municipio" error={errors.municipio?.message} {...register('municipio')} />
      </div>

      <datalist id="departamentos-gt">
        {DEPARTAMENTOS_GUATEMALA.map((d) => (
          <option key={d} value={d} />
        ))}
      </datalist>

      <CampoFormulario etiqueta="Dirección (calle, zona, número)" error={errors.direccion?.message} {...register('direccion')} />
      <CampoFormulario etiqueta="Referencia (opcional)" error={errors.referencia?.message} {...register('referencia')} />

      <label className="flex items-center gap-2 text-sm text-gray-700">
        <input type="checkbox" {...register('esPredeterminada')} />
        Usar como dirección predeterminada
      </label>

      <div className="flex gap-2">
        <Boton type="submit" cargando={isSubmitting}>
          Guardar dirección
        </Boton>
        {alCancelar && (
          <Boton variante="secundario" onClick={alCancelar} disabled={isSubmitting}>
            Cancelar
          </Boton>
        )}
      </div>
    </form>
  );
}