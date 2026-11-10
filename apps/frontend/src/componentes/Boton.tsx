import type { ComponentProps } from 'react';
import { claseBoton, type VarianteBoton } from './estilosBoton';

interface Propiedades extends ComponentProps<'button'> {
  cargando?: boolean;
  variante?: VarianteBoton;
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
  return (
    <button
      type={type}
      disabled={disabled || cargando}
      aria-busy={cargando || undefined}
      className={claseBoton(variante, className)}
      {...resto}
    >
      {cargando ? (
        <>
          <span
            aria-hidden="true"
            className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent motion-reduce:animate-none"
          />
          Procesando...
        </>
      ) : (
        children
      )}
    </button>
  );
}
