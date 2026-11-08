import { useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';

export function useParametrosUrl() {
  const [params, setParams] = useSearchParams();

  const actualizar = useCallback(
    (cambios: Record<string, string | undefined>) => {
      setParams(
        (previos) => {
          const siguientes = new URLSearchParams(previos);
          for (const [clave, valor] of Object.entries(cambios)) {
            if (valor === undefined || valor === '') siguientes.delete(clave);
            else siguientes.set(clave, valor);
          }
          if (!('pagina' in cambios)) siguientes.delete('pagina');
          return siguientes;
        },
        { replace: !('pagina' in cambios) }
      );
    },
    [setParams]
  );

  const limpiar = useCallback(() => setParams({}, { replace: true }), [setParams]);

  return { params, actualizar, limpiar };
}