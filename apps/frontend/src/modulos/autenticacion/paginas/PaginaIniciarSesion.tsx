import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Link, Navigate, useLocation } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { aplicarErrorServidor } from '../../../utilidades/formularios';
import { rutaInicialPorRol } from '../../../utilidades/rutas';
import { inicioSesionEsquema, type DatosInicioSesion } from '../esquemas/autenticacionEsquema';
import { iniciarSesion } from '../servicios/autenticacionServicio';

export function PaginaIniciarSesion() {
  const usuarioActual = useSesionEstado((e) => e.usuario);
  const ubicacion = useLocation();
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<DatosInicioSesion>({ resolver: zodResolver(inicioSesionEsquema) });

  const desde = (ubicacion.state as { desde?: string } | null)?.desde;

  if (usuarioActual) {
    return <Navigate to={desde ?? rutaInicialPorRol(usuarioActual.rol)} replace />;
  }

  const alEnviar = handleSubmit(async (datos) => {
    setErrorGeneral(null);
    try {
      await iniciarSesion(datos);
    } catch (error) {
      setErrorGeneral(aplicarErrorServidor(error, setError, ['correo', 'contrasena']));
    }
  });

  return (
    <main className="mx-auto w-full max-w-md p-6">
      <h1 className="mb-6 text-2xl font-semibold">Iniciar sesión</h1>

      <form onSubmit={alEnviar} noValidate className="space-y-4 rounded-lg border border-gray-200 bg-white p-6">
        {errorGeneral && (
          <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
            {errorGeneral}
          </p>
        )}

        <CampoFormulario
          etiqueta="Correo electrónico"
          type="email"
          autoComplete="email"
          error={errors.correo?.message}
          {...register('correo')}
        />
        <CampoFormulario
          etiqueta="Contraseña"
          type="password"
          autoComplete="current-password"
          error={errors.contrasena?.message}
          {...register('contrasena')}
        />

        <Boton type="submit" cargando={isSubmitting} className="w-full">
          Entrar
        </Boton>
      </form>

      <p className="mt-4 text-center text-sm text-gray-600">
        ¿No tienes cuenta?{' '}
        <Link to="/registro" className="font-medium text-indigo-600 hover:underline">
          Regístrate
        </Link>
      </p>
    </main>
  );
}