import { useId, type ComponentProps } from 'react';

interface Propiedades extends ComponentProps<'input'> {
  etiqueta: string;
  error?: string;
}

export function CampoFormulario({ etiqueta, error, className = '', ...resto }: Propiedades) {
  const id = useId();

  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-sm font-medium text-gray-700">
        {etiqueta}
      </label>
      <input
        id={id}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${id}-error` : undefined}
        className={`control ${error ? 'border-red-500 hover:border-red-500' : ''} ${className}`}
        {...resto}
      />
      {error && (
        <p id={`${id}-error`} className="mt-1.5 text-sm text-red-600">
          {error}
        </p>
      )}
    </div>
  );
}
