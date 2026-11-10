import { NavLink } from 'react-router-dom';

const secciones = [
  { ruta: '/gestion/inventario', etiqueta: 'Existencias', exacta: true },
  { ruta: '/gestion/inventario/kardex', etiqueta: 'Kardex', exacta: false },
  { ruta: '/gestion/inventario/conciliacion', etiqueta: 'Conciliación', exacta: false },
];

export function NavegacionInventario() {
  return (
    <nav aria-label="Secciones de inventario" className="-mx-4 flex gap-1 overflow-x-auto border-b border-slate-200 px-4 sm:mx-0 sm:px-0">
      {secciones.map((s) => (
        <NavLink
          key={s.ruta}
          to={s.ruta}
          end={s.exacta}
          className={({ isActive }) =>
            `-mb-px inline-flex min-h-11 items-center whitespace-nowrap border-b-2 px-4 text-sm font-medium transition-colors duration-150 ${
              isActive ? 'border-marca-600 text-marca-700' : 'border-transparent text-slate-600 hover:border-slate-300 hover:text-slate-900'
            }`
          }
        >
          {s.etiqueta}
        </NavLink>
      ))}
    </nav>
  );
}