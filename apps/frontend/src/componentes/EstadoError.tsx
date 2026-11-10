import { normalizarError } from '../servicios/errorServicio';
import { Boton } from './Boton';

interface Propiedades {
  error: unknown;
  onReintentar?: () => void;
}

export function EstadoError({ error, onReintentar }: Propiedades) {
  const { mensaje } = normalizarError(error);

  return (
    <div role="alert" className="flex flex-col items-center px-6 py-12 text-center">
      <span aria-hidden="true" className="flex h-12 w-12 items-center justify-center rounded-full bg-red-50 text-red-600">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-6 w-6">
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v4m0 4h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
        </svg>
      </span>
      <p className="mt-4 max-w-md font-medium text-slate-900">{mensaje}</p>
      {onReintentar && (
        <Boton variante="secundario" onClick={onReintentar} className="mt-4">
          Reintentar
        </Boton>
      )}
    </div>
  );
}
