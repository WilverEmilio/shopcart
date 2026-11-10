import { Link } from 'react-router-dom';
import { useSesionEstado } from '../estados/sesionEstado';
import { rutaInicialPorRol } from '../utilidades/rutas';
import { claseBoton } from './estilosBoton';

export function PaginaNoEncontrada() {
  const usuario = useSesionEstado((e) => e.usuario);
  const destino = usuario ? rutaInicialPorRol(usuario.rol) : '/catalogo';

  return (
    <main className="mx-auto max-w-md px-4 py-16 text-center sm:py-24">
      <p className="text-sm font-semibold text-marca-700">Error 404</p>
      <h1 className="mt-2 text-4xl font-bold">Página no encontrada</h1>
      <p className="mt-3 text-slate-600">La dirección que buscas no existe o fue movida.</p>
      <Link to={destino} className={claseBoton('primario', 'mt-8')}>
        Ir al inicio
      </Link>
    </main>
  );
}
