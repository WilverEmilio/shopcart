import { Link } from 'react-router-dom';
import { useSesionEstado } from '../estados/sesionEstado';
import { rutaInicialPorRol } from '../utilidades/rutas';

export function PaginaNoEncontrada() {
  const usuario = useSesionEstado((e) => e.usuario);
  const destino = usuario ? rutaInicialPorRol(usuario.rol) : '/catalogo';

  return (
    <main className="mx-auto max-w-md p-10 text-center">
      <p className="text-5xl font-bold text-gray-300">404</p>
      <h1 className="mt-3 text-xl font-semibold">Página no encontrada</h1>
      <p className="mt-2 text-sm text-gray-500">La dirección que buscas no existe o fue movida.</p>
      <Link to={destino} className="mt-6 inline-block rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">
        Ir al inicio
      </Link>
    </main>
  );
}