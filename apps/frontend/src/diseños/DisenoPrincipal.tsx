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
  `inline-flex min-h-11 items-center rounded-control px-3 text-sm font-medium transition-colors duration-150 motion-reduce:transition-none md:min-h-9 ${
    isActive ? 'bg-marca-50 text-marca-700' : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
  }`;

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
      <header className="sticky top-0 z-30 border-b border-gray-200 bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/80">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-x-4 gap-y-2 px-4 py-2 sm:px-6">
          <Link to="/" className="flex min-h-11 items-center gap-2 text-lg font-bold tracking-tight text-gray-900">
            <span aria-hidden="true" className="flex h-8 w-8 items-center justify-center rounded-control bg-marca-600 text-white">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5">
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 4h2l2.4 11.2a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.5L21 8H6" />
                <circle cx="10" cy="20" r="1" />
                <circle cx="17" cy="20" r="1" />
              </svg>
            </span>
            ShopCart
          </Link>

          <button
            type="button"
            aria-label={menuAbierto ? 'Cerrar menú' : 'Abrir menú'}
            aria-expanded={menuAbierto}
            aria-controls="menu-principal"
            onClick={() => setMenuAbierto((abierto) => !abierto)}
            className="relative flex h-11 w-11 items-center justify-center rounded-control border border-gray-300 text-gray-700 hover:bg-gray-50 md:hidden"
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
            className={`${menuAbierto ? 'flex' : 'hidden'} w-full flex-col gap-1 pb-2 md:flex md:w-auto md:flex-row md:flex-wrap md:items-center md:pb-0`}
          >
            {elementos.map((e) => (
              <NavLink key={e.ruta} to={e.ruta} className={claseEnlace} onClick={() => setMenuAbierto(false)}>
                {e.etiqueta}
                {e.ruta === '/carrito' && cantidadCarrito > 0 && (
                  <span className="ml-2 inline-flex min-w-5 items-center justify-center rounded-full bg-marca-600 px-1.5 py-0.5 text-xs font-semibold tabular-nums text-white">
                    {cantidadCarrito}
                    <span className="sr-only"> {cantidadCarrito === 1 ? 'producto' : 'productos'}</span>
                  </span>
                )}
              </NavLink>
            ))}

            <div className="mt-1 flex flex-wrap items-center gap-2 border-t border-gray-200 pt-3 md:ml-3 md:mt-0 md:border-0 md:border-l md:pl-4 md:pt-0">
              {usuario ? (
                <>
                  <span className="min-w-0 flex-1 truncate text-sm text-gray-700 md:max-w-48 md:flex-none">
                    <span className="font-medium">{usuario.nombres}</span>{' '}
                    <span className="text-gray-500">({usuario.rol})</span>
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
                    className="inline-flex min-h-11 items-center rounded-control bg-marca-600 px-3 text-sm font-medium text-white shadow-sm transition-colors hover:bg-marca-700 md:min-h-9"
                  >
                    Registrarse
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
      <footer className="border-t border-gray-200 bg-white">
        <p className="mx-auto max-w-7xl px-4 py-6 text-center text-xs text-gray-600 sm:px-6">
          ShopCart · Precios en quetzales (GTQ) con IVA incluido.
        </p>
      </footer>
    </div>
  );
}
