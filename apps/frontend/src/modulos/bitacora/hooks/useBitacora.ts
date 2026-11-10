import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { listarBitacora } from '../servicios/bitacoraServicio';
import type { FiltrosBitacora } from '../tipos/bitacora';

export function useBitacora(filtros: FiltrosBitacora) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: ['bitacora', filtros],
    queryFn: ({ signal }) => listarBitacora(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}