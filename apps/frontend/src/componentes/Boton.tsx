import type { ComponentProps } from 'react';

interface Propiedades extends ComponentProps<'button'> {
  cargando?: boolean;
  variante?: 'primario' | 'secundario';
}

export function Boton({
  cargando = false,
  variante = 'primario',
  type = 'button',
  disabled,
  children,
  className = '',
  ...resto
}: Propiedades) {
  const estilos =
    variante === 'primario'
      ? 'bg-indigo-600 text-white hover:bg-indigo-700'
      : 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-100';

  return (
    <button
      type={type}
      disabled={disabled || cargando}
      className={`rounded-md px-4 py-2 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-60 ${estilos} ${className}`}
      {...resto}
    >
      {cargando ? 'Procesando...' : children}
    </button>
  );
}