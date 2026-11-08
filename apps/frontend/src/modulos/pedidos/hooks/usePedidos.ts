import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import {
  avanzarEstado,
  cancelarPedido,
  listarMisPedidos,
  listarPedidosGestion,
  listarTransiciones,
  obtenerDetallePedido,
  registrarDevolucion,
} from '../servicio/pedidosServicio';
import type { DatosDevolucion, EstadoAvance, FiltrosMisPedidos, FiltrosPedidosGestion } from '../tipos/pedido';

const RAIZ = ['pedidos'] as const;

export const clavesPedidos = {
  mios: (f: FiltrosMisPedidos) => [...RAIZ, 'mios', f] as const,
  gestion: (f: FiltrosPedidosGestion) => [...RAIZ, 'gestion', f] as const,
  detalle: (id: number | undefined) => [...RAIZ, 'detalle', id] as const,
  transiciones: [...RAIZ, 'transiciones'] as const,
};

export function useMisPedidos(filtros: FiltrosMisPedidos) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: clavesPedidos.mios(filtros),
    queryFn: ({ signal }) => listarMisPedidos(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function usePedidosGestion(filtros: FiltrosPedidosGestion) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: clavesPedidos.gestion(filtros),
    queryFn: ({ signal }) => listarPedidosGestion(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useDetallePedido(idPedido: number | undefined) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: clavesPedidos.detalle(idPedido),
    queryFn: ({ signal }) => obtenerDetallePedido(idPedido as number, signal),
    enabled: inicializada && idPedido !== undefined,
  });
}

export function useTransiciones() {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: clavesPedidos.transiciones,
    queryFn: ({ signal }) => listarTransiciones(signal),
    staleTime: 10 * 60_000,
    enabled: inicializada,
  });
}

export function useAccionesPedido() {
  const cliente = useQueryClient();
  const refrescar = () => cliente.invalidateQueries({ queryKey: RAIZ });

  const cancelar = useMutation({
    mutationFn: ({ idPedido, motivo }: { idPedido: number; motivo: string }) => cancelarPedido(idPedido, motivo),
    onSuccess: refrescar,
  });

  const avanzar = useMutation({
    mutationFn: ({ idPedido, estado, comentario }: { idPedido: number; estado: EstadoAvance; comentario: string | null }) =>
      avanzarEstado(idPedido, estado, comentario),
    onSuccess: refrescar,
  });

  const devolver = useMutation({
    mutationFn: ({ idPedido, datos }: { idPedido: number; datos: DatosDevolucion }) =>
      registrarDevolucion(idPedido, datos),
    onSuccess: refrescar,
  });

  return { cancelar, avanzar, devolver };
}