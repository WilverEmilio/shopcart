import { useState } from 'react';
import { Suspense } from 'react';
import { EstadoCarga } from '../componentes/EstadoCarga';
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom';
import { Boton } from '../componentes/Boton';
import { menuPara } from '../configuracion/menu';
import { useSesionEstado } from '../estados/sesionEstado';
import { cerrarSesion } from '../modulos/autenticacion/servicios/autenticacionServicio';
import { useCarrito } from '../modulos/carrito/hooks/useCarrito';

const claseEnlace = ({ isActive }: { isActive: boolean }) =>
  `inline-flex min-h-11 items-center rounded-control px-3 text-sm font-medium transition-colors duration-150 motion-reduce:transition-none lg:min-h-9 ${
    isActive ? 'bg-marca-50 text-marca-800' : 'text-slate-700 hover:bg-slate-100 hover:text-slate-900'
  }`;

function Logotipo() {
  return (
    <Link to="/" className="flex min-h-11 items-center gap-2.5" aria-label="ShopCart, ir al inicio">
      <span aria-hidden="true" className="flex h-9 w-9 items-center justify-center rounded-xl bg-marca-700 text-white shadow-sm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5">
          <path strokeLinecap="round" strokeLinejoin="round" d="M6 7h12l-1 12a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L6 7Z" />
          <path strokeLinecap="round" d="M9 7V6a3 3 0 0 1 6 0v1" />
        </svg>
      </span>
      <span className="font-display text-xl font-bold tracking-tight text-slate-900">ShopCart</span>
    </Link>
  );
}

export function DisenoPrincipal() {
  const usuario = useSesionEstado((e) => e.usuario);
  const navigate = useNavigate();
  const [menuAbierto, setMenuAbierto] = useState(false);

  const elementos = menuPara(usuario?.rol ?? null);
  const puedeVerCarrito = !usuario || usuario.rol === 'Cliente';
  const { data: carrito } = useCarrito(puedeVerCarrito);
  const cantidadCarrito = carrito?.items.reduce((total, i) => total + i.cantidad, 0) ?? 0;

  const alCerrarSesion = async () => {
    await cerrarSesion();
    setMenuAbierto(false);
    navigate('/', { replace: true });
  };

  return (
    <div className="flex min-h-screen flex-col">
      <header className="sticky top-0 z-30 border-b border-slate-200 bg-white/95 shadow-[0_1px_0_0_rgb(15_23_42/0.02)] backdrop-blur supports-[backdrop-filter]:bg-white/85">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-x-6 gap-y-2 px-4 py-2.5 sm:px-6">
          <Logotipo />

          <button
            type="button"
            aria-label={menuAbierto ? 'Cerrar menú' : 'Abrir menú'}
            aria-expanded={menuAbierto}
            aria-controls="menu-principal"
            onClick={() => setMenuAbierto((abierto) => !abierto)}
            className="relative flex h-11 w-11 items-center justify-center rounded-control border border-slate-300 text-slate-700 hover:bg-slate-50 lg:hidden"
          >
            <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5">
              {menuAbierto ? <path strokeLinecap="round" d="M6 6l12 12M18 6 6 18" /> : <path strokeLinecap="round" d="M4 7h16M4 12h16M4 17h16" />}
            </svg>
            {!menuAbierto && cantidadCarrito > 0 && (
              <span aria-hidden="true" className="absolute -right-1 -top-1 h-3 w-3 rounded-full bg-marca-600 ring-2 ring-white" />
            )}
          </button>

          <nav
            id="menu-principal"
            aria-label="Principal"
            className={`${menuAbierto ? 'flex' : 'hidden'} w-full flex-col gap-1 pb-3 lg:flex lg:w-auto lg:flex-row lg:items-center lg:pb-0`}
          >
            {elementos.map((e) => (
              <NavLink key={e.ruta} to={e.ruta} className={claseEnlace} onClick={() => setMenuAbierto(false)}>
                {e.etiqueta}
                {e.ruta === '/carrito' && cantidadCarrito > 0 && (
                  <span className="ml-2 inline-flex min-w-5 items-center justify-center rounded-full bg-marca-700 px-1.5 py-0.5 text-xs font-semibold tabular-nums text-white">
                    {cantidadCarrito}
                    <span className="sr-only"> {cantidadCarrito === 1 ? 'producto' : 'productos'}</span>
                  </span>
                )}
              </NavLink>
            ))}

            <div className="mt-2 flex flex-wrap items-center gap-2 border-t border-slate-200 pt-3 lg:ml-3 lg:mt-0 lg:border-0 lg:border-l lg:pl-4 lg:pt-0">
              {usuario ? (
                <>
                  <span className="min-w-0 flex-1 truncate text-sm text-slate-700 lg:max-w-44 lg:flex-none">
                    <span className="font-medium text-slate-900">{usuario.nombres}</span>{' '}
                    <span className="text-slate-500">({usuario.rol})</span>
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
                  <NavLink
                    to="/registro"
                    onClick={() => setMenuAbierto(false)}
                    className="inline-flex min-h-11 items-center rounded-control bg-marca-700 px-4 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-marca-800 lg:min-h-9"
                  >
                    Crear cuenta
                  </NavLink>
                </>
              )}
            </div>
          </nav>
        </div>
      </header>

      <div className="flex-1">
        <Suspense fallback={<EstadoCarga />}>
          <Outlet />
        </Suspense>
      </div>

      <footer className="mt-12 border-t border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl flex-col gap-6 px-4 py-8 sm:flex-row sm:items-start sm:justify-between sm:px-6">
          <div className="max-w-xs">
            <p className="font-display text-lg font-bold text-slate-900">ShopCart</p>
            <p className="mt-1 text-sm text-slate-600">Precios en quetzales con IVA incluido. Envíos a los 22 departamentos.</p>
          </div>
          {elementos.length > 0 && (
            <nav aria-label="Pie de página">
              <ul className="flex flex-wrap gap-x-6 gap-y-1 text-sm">
                {elementos.map((e) => (
                  <li key={e.ruta}>
                    <Link to={e.ruta} className="inline-flex min-h-10 items-center text-slate-600 hover:text-marca-700">
                      {e.etiqueta}
                    </Link>
                  </li>
                ))}
              </ul>
            </nav>
          )}
        </div>
      </footer>
    </div>
  );
}
