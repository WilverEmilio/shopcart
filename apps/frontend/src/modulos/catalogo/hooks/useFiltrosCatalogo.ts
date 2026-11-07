import { useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import type { FiltrosCatalogo, OrdenCatalogo } from '../tipos/catalogo';

export const TAMANO_PAGINA_CATALOGO = 12;

export const OPCIONES_ORDEN = [
  { valor: 'Nombre|ASC', etiqueta: 'Nombre (A-Z)' },
  { valor: 'Nombre|DESC', etiqueta: 'Nombre (Z-A)' },
  { valor: 'Precio|ASC', etiqueta: 'Precio: menor a mayor' },
  { valor: 'Precio|DESC', etiqueta: 'Precio: mayor a menor' },
  { valor: 'FechaCreacion|DESC', etiqueta: 'Más recientes' },
] as const;

type ClaveFiltro = 'texto' | 'categoria' | 'min' | 'max' | 'disponibles' | 'orden' | 'dir' | 'pagina';
export type CambiosFiltros = Partial<Record<ClaveFiltro, string | undefined>>;

const numero = (valor: string | null): number | undefined => {
  if (!valor) return undefined;
  const n = Number(valor);
  return Number.isFinite(n) ? n : undefined;
};

export function useFiltrosCatalogo() {
  const [params, setParams] = useSearchParams();

  const filtros = useMemo<FiltrosCatalogo>(() => {
    const orden = params.get('orden');
    const ordenarPor: OrdenCatalogo = orden === 'Precio' || orden === 'FechaCreacion' ? orden : 'Nombre';

    return {
      texto: params.get('texto') || undefined,
      idCategoria: numero(params.get('categoria')),
      precioMinimo: numero(params.get('min')),
      precioMaximo: numero(params.get('max')),
      soloDisponibles: params.get('disponibles') === 'true',
      ordenarPor,
      direccion: params.get('dir') === 'DESC' ? 'DESC' : 'ASC',
      pagina: Math.max(1, Math.trunc(numero(params.get('pagina')) ?? 1)),
      registrosPorPagina: TAMANO_PAGINA_CATALOGO,
    };
  }, [params]);

  const actualizar = useCallback(
    (cambios: CambiosFiltros) => {
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

  return { filtros, actualizar, limpiar };
}