import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Link, Navigate } from 'react-router-dom';
import { Boton } from '../../../componentes/botones/Boton';
import { CampoFormulario } from '../../../componentes/formularios/CampoFormulario';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { normalizarError } from '../../../servicios/errorServicio';
import { aplicarErrorServidor } from '../../../utilidades/formularios';
import { rutaInicialPorRol } from '../../../utilidades/rutas';
import { registroEsquema, type DatosRegistro } from '../esquemas/autenticacionEsquema';
import { iniciarSesion, registrarCliente } from '../servicios/autenticacionServicio';

const CODIGO_CORREO_DUPLICADO = 50010;

export function PaginaRegistro() {
  const usuarioActual = useSesionEstado((e) => e.usuario);
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<DatosRegistro>({
    resolver: zodResolver(registroEsquema),
    defaultValues: { telefono: '' },
  });

  if (usuarioActual) {
    return <Navigate to={rutaInicialPorRol(usuarioActual.rol)} replace />;
  }

  const alEnviar = handleSubmit(async (datos) => {
    setErrorGeneral(null);
    try {
      await registrarCliente({
        correo: datos.correo,
        contrasena: datos.contrasena,
        nombres: datos.nombres,
        apellidos: datos.apellidos,
        telefono: datos.telefono || null,
      });
      await iniciarSesion({ correo: datos.correo, contrasena: datos.contrasena });
    } catch (error) {
      if (normalizarError(error).codigo === CODIGO_CORREO_DUPLICADO) {
        setError('correo', { type: 'servidor', message: 'Este correo ya está registrado.' });
        return;
      }
      setErrorGeneral(
        aplicarErrorServidor(error, setError, ['correo', 'contrasena', 'nombres', 'apellidos', 'telefono'])
      );
    }
  });

  return (
    <main className="mx-auto w-full max-w-md p-6">
      <h1 className="mb-6 text-2xl font-semibold">Crear cuenta</h1>

      <form onSubmit={alEnviar} noValidate className="space-y-4 rounded-lg border border-gray-200 bg-white p-6">
        {errorGeneral && (
          <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
            {errorGeneral}
          </p>
        )}

        <div className="grid gap-4 sm:grid-cols-2">
          <CampoFormulario etiqueta="Nombres" autoComplete="given-name" error={errors.nombres?.message} {...register('nombres')} />
          <CampoFormulario etiqueta="Apellidos" autoComplete="family-name" error={errors.apellidos?.message} {...register('apellidos')} />
        </div>

        <CampoFormulario etiqueta="Correo electrónico" type="email" autoComplete="email" error={errors.correo?.message} {...register('correo')} />
        <CampoFormulario etiqueta="Teléfono (opcional)" type="tel" autoComplete="tel" error={errors.telefono?.message} {...register('telefono')} />
        <CampoFormulario etiqueta="Contraseña" type="password" autoComplete="new-password" error={errors.contrasena?.message} {...register('contrasena')} />
        <CampoFormulario etiqueta="Confirmar contraseña" type="password" autoComplete="new-password" error={errors.confirmarContrasena?.message} {...register('confirmarContrasena')} />

        <Boton type="submit" cargando={isSubmitting} className="w-full">
          Crear cuenta
        </Boton>
      </form>

      <p className="mt-4 text-center text-sm text-gray-600">
        ¿Ya tienes cuenta?{' '}
        <Link to="/iniciar-sesion" className="font-medium text-indigo-600 hover:underline">
          Inicia sesión
        </Link>
      </p>
    </main>
  );
}