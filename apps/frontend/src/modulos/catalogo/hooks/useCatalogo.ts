import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import {
  listarCategoriasPublicas,
  listarProductos,
  obtenerDetalleProducto,
} from '../servicios/productosServicio';
import type { FiltrosCatalogo } from '../tipos/catalogo';

export const clavesCatalogo = {
  productos: (filtros: FiltrosCatalogo) => ['catalogo', 'productos', filtros] as const,
  categorias: ['catalogo', 'categorias-activas'] as const,
  detalle: (idProducto: number | undefined) => ['catalogo', 'producto', idProducto] as const,
};

export function useProductos(filtros: FiltrosCatalogo) {
  const inicializada = useSesionEstado((e) => e.inicializada);

  return useQuery({
    queryKey: clavesCatalogo.productos(filtros),
    queryFn: ({ signal }) => listarProductos(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useCategoriasPublicas() {
  return useQuery({
    queryKey: clavesCatalogo.categorias,
    queryFn: ({ signal }) => listarCategoriasPublicas(signal),
    staleTime: 5 * 60_000,
  });
}

export function useDetalleProducto(idProducto: number | undefined) {
  const inicializada = useSesionEstado((e) => e.inicializada);

  return useQuery({
    queryKey: clavesCatalogo.detalle(idProducto),
    queryFn: ({ signal }) => obtenerDetalleProducto(idProducto as number, signal),
    enabled: inicializada && idProducto !== undefined,
  });
}