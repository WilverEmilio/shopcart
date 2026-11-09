import { NavLink } from 'react-router-dom';

const secciones = [
  { ruta: '/gestion/inventario', etiqueta: 'Existencias', exacta: true },
  { ruta: '/gestion/inventario/kardex', etiqueta: 'Kardex', exacta: false },
  { ruta: '/gestion/inventario/conciliacion', etiqueta: 'Conciliación', exacta: false },
];

export function NavegacionInventario() {
  return (
    <nav aria-label="Secciones de inventario" className="flex gap-2 border-b border-gray-200">
      {secciones.map((s) => (
        <NavLink
          key={s.ruta}
          to={s.ruta}
          end={s.exacta}
          className={({ isActive }) =>
            `-mb-px border-b-2 px-4 py-2 text-sm font-medium ${
              isActive ? 'border-indigo-600 text-indigo-700' : 'border-transparent text-gray-600 hover:text-gray-900'
            }`
          }
        >
          {s.etiqueta}
        </NavLink>
      ))}
    </nav>
  );
}