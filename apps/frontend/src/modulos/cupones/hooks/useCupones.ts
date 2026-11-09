import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import {
  actualizarCupon,
  cambiarEstadoCupon,
  crearCupon,
  eliminarCupon,
  listarCupones,
} from '../servicios/cuponesServicio';
import type { DatosCupon, DatosCuponNuevo, FiltrosCupones } from '../tipos/cupon';

export function useCupones(filtros: FiltrosCupones) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: ['cupones', filtros],
    queryFn: ({ signal }) => listarCupones(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useAccionesCupon() {
  const cliente = useQueryClient();
  const refrescar = () => cliente.invalidateQueries({ queryKey: ['cupones'] });

  const crear = useMutation({ mutationFn: (datos: DatosCuponNuevo) => crearCupon(datos), onSuccess: refrescar });
  const actualizar = useMutation({
    mutationFn: ({ idCupon, datos }: { idCupon: number; datos: DatosCupon }) => actualizarCupon(idCupon, datos),
    onSuccess: refrescar,
  });
  const cambiarEstado = useMutation({
    mutationFn: ({ idCupon, activo }: { idCupon: number; activo: boolean }) => cambiarEstadoCupon(idCupon, activo),
    onSuccess: refrescar,
  });
  const eliminar = useMutation({ mutationFn: (idCupon: number) => eliminarCupon(idCupon), onSuccess: refrescar });

  return { crear, actualizar, cambiarEstado, eliminar };
}