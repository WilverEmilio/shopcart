import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import {
  listarExistencias,
  listarKardex,
  obtenerConciliacion,
  registrarAjuste,
  registrarEntrada,
} from '../servicios/inventarioServicio';
import type { FiltrosConciliacion, FiltrosExistencias, FiltrosKardex } from '../tipos/inventario';

const RAIZ = ['inventario'] as const;

export function useExistencias(filtros: FiltrosExistencias) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: [...RAIZ, 'existencias', filtros],
    queryFn: ({ signal }) => listarExistencias(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useKardex(filtros: FiltrosKardex) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: [...RAIZ, 'kardex', filtros],
    queryFn: ({ signal }) => listarKardex(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useConciliacion(filtros: FiltrosConciliacion) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: [...RAIZ, 'conciliacion', filtros],
    queryFn: ({ signal }) => obtenerConciliacion(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useMovimientosInventario() {
  const cliente = useQueryClient();

  const refrescar = () =>
    Promise.all([
      cliente.invalidateQueries({ queryKey: RAIZ }),
      cliente.invalidateQueries({ queryKey: ['catalogo'] }),
    ]);

  const entrada = useMutation({ mutationFn: registrarEntrada, onSuccess: refrescar });
  const ajuste = useMutation({ mutationFn: registrarAjuste, onSuccess: refrescar });

  return { entrada, ajuste };
}