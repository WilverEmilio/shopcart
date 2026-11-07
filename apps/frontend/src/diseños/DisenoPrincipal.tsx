import { useState } from 'react';
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { Boton } from '../componentes/Boton';
import { menuPara } from '../configuracion/menu';
import { useSesionEstado } from '../estados/sesionEstado';
import { cerrarSesion } from '../modulos/autenticacion/servicios/autenticacionServicio';

const claseEnlace = ({ isActive }: { isActive: boolean }) =>
  `rounded-md px-3 py-2 text-sm font-medium ${
    isActive ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-100'
  }`;

export function DisenoPrincipal() {
  const usuario = useSesionEstado((e) => e.usuario);
  const navigate = useNavigate();
  const [menuAbierto, setMenuAbierto] = useState(false);

  const elementos = menuPara(usuario?.rol ?? null);

  const alCerrarSesion = async () => {
    await cerrarSesion();
    setMenuAbierto(false);
    navigate('/', { replace: true });
  };

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-gray-200 bg-white">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-2 px-4 py-3">
          <Link to="/" className="text-lg font-bold text-indigo-600">
            ShopCart
          </Link>

          <button
            type="button"
            aria-label="Abrir menú"
            aria-expanded={menuAbierto}
            onClick={() => setMenuAbierto((abierto) => !abierto)}
            className="rounded-md border border-gray-300 px-3 py-1 text-lg md:hidden"
          >
            ☰
          </button>

          <nav
            className={`${menuAbierto ? 'flex' : 'hidden'} w-full flex-col gap-1 md:flex md:w-auto md:flex-row md:flex-wrap md:items-center`}
          >
            {elementos.map((e) => (
              <NavLink key={e.ruta} to={e.ruta} className={claseEnlace} onClick={() => setMenuAbierto(false)}>
                {e.etiqueta}
              </NavLink>
            ))}

            <div className="flex items-center gap-3 border-t border-gray-200 pt-2 md:ml-4 md:border-0 md:pt-0">
              {usuario ? (
                <>
                  <span className="text-sm text-gray-600">
                    {usuario.nombres} <span className="text-gray-400">({usuario.rol})</span>
                  </span>
                  <Boton variante="secundario" onClick={alCerrarSesion}>
                    Cerrar sesión
                  </Boton>
                </>
              ) : (
                <>
                  <NavLink to="/iniciar-sesion" className={claseEnlace} onClick={() => setMenuAbierto(false)}>
                    Iniciar sesión
                  </NavLink>
                  <NavLink to="/registro" className={claseEnlace} onClick={() => setMenuAbierto(false)}>
                    Registrarse
                  </NavLink>
                </>
              )}
            </div>
          </nav>
        </div>
      </header>

      <div className="flex-1">
        <Outlet />
      </div>
    </div>
  );
}