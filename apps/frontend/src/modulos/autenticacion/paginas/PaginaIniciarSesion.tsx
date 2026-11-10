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
    <main className="mx-auto w-full max-w-md px-4 py-10 sm:py-16">
      <div className="mb-6 text-center">
        <h1 className="text-3xl font-bold sm:text-4xl">Iniciar sesión</h1>
        <p className="mt-2 text-sm text-slate-600">Entra para pagar y ver tus pedidos. Tu carrito se conserva.</p>
      </div>

      <form onSubmit={alEnviar} noValidate className="tarjeta space-y-4 p-5 sm:p-8">
        {errorGeneral && (
          <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
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

      <p className="mt-6 text-center text-sm text-slate-600">
        ¿No tienes cuenta?{' '}
        <Link to="/registro" className="font-medium text-marca-700 hover:underline">
          Regístrate
        </Link>
      </p>
    </main>
  );
}