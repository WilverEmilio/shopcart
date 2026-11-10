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
    <form onSubmit={alEnviar} noValidate className="tarjeta space-y-4 p-4 sm:p-5">
      <h3 className="font-semibold">Nueva dirección de entrega</h3>

      {errorGeneral && (
        <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {errorGeneral}
        </p>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <CampoFormulario etiqueta="Nombre de quien recibe" autoComplete="name" error={errors.nombreDestinatario?.message} {...register('nombreDestinatario')} />
        <CampoFormulario etiqueta="Teléfono" type="tel" inputMode="tel" autoComplete="tel" error={errors.telefono?.message} {...register('telefono')} />
        <CampoFormulario etiqueta="Departamento" list="departamentos-gt" autoComplete="address-level1" error={errors.departamento?.message} {...register('departamento')} />
        <CampoFormulario etiqueta="Municipio" autoComplete="address-level2" error={errors.municipio?.message} {...register('municipio')} />
      </div>

      <datalist id="departamentos-gt">
        {DEPARTAMENTOS_GUATEMALA.map((d) => (
          <option key={d} value={d} />
        ))}
      </datalist>

      <CampoFormulario etiqueta="Dirección (calle, zona, número)" autoComplete="street-address" error={errors.direccion?.message} {...register('direccion')} />
      <CampoFormulario etiqueta="Referencia (opcional)" error={errors.referencia?.message} {...register('referencia')} />

      <label className="flex min-h-10 cursor-pointer items-center gap-3 text-sm text-slate-700">
        <input type="checkbox" className="h-4 w-4" {...register('esPredeterminada')} />
        Usar como dirección predeterminada
      </label>

      <div className="flex flex-col gap-2 sm:flex-row">
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