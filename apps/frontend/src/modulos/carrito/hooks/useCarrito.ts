import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { CLAVE_CARRITO } from '../constantes';
import {
  actualizarCantidad,
  agregarItem,
  aplicarCupon,
  eliminarItem,
  obtenerCarrito,
  quitarCupon,
} from '../servicios/carritoServicio';
import type { Carrito } from '../tipos/carrito';

export function useCarrito(habilitado = true) {
  const inicializada = useSesionEstado((e) => e.inicializada);

  return useQuery({
    queryKey: CLAVE_CARRITO,
    queryFn: ({ signal }) => obtenerCarrito(signal),
    enabled: inicializada && habilitado,
  });
}

export function useAccionesCarrito() {
  const cliente = useQueryClient();
  const guardar = (carrito: Carrito) => {
    cliente.setQueryData(CLAVE_CARRITO, carrito);
  };

  const agregar = useMutation({
    mutationFn: ({ idVariante, cantidad }: { idVariante: number; cantidad: number }) =>
      agregarItem(idVariante, cantidad),
    onSuccess: guardar,
  });

  const cambiarCantidad = useMutation({
    mutationFn: ({ idVariante, cantidad }: { idVariante: number; cantidad: number }) =>
      actualizarCantidad(idVariante, cantidad),
    onSuccess: guardar,
  });

  const eliminar = useMutation({
    mutationFn: (idVariante: number) => eliminarItem(idVariante),
    onSuccess: guardar,
  });

  const aplicar = useMutation({
    mutationFn: (codigo: string) => aplicarCupon(codigo),
    onSuccess: guardar,
  });

  const quitar = useMutation({
    mutationFn: () => quitarCupon(),
    onSuccess: guardar,
  });

  const todas = [agregar, cambiarCantidad, eliminar, aplicar, quitar];

  return {
    agregar,
    cambiarCantidad,
    eliminar,
    aplicarCupon: aplicar,
    quitarCupon: quitar,
    ocupado: todas.some((m) => m.isPending),
    reiniciarErrores: () => todas.forEach((m) => m.reset()),
  };
}

export type AccionesCarrito = ReturnType<typeof useAccionesCarrito>;