import { keepPreviousData, useQuery } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import {
  carritosAbandonados,
  obtenerResumen,
  topProductos,
  ventasPorCategoria,
  ventasPorPeriodo,
} from '../servicios/reportesServicio';
import type { Agrupacion, FiltrosAbandonados, OrdenTop, RangoFechas } from '../tipos/reportes';

function useListo() {
  return useSesionEstado((e) => e.inicializada);
}

export function useResumen(rango: RangoFechas) {
  const listo = useListo();
  return useQuery({
    queryKey: ['reportes', 'resumen', rango],
    queryFn: ({ signal }) => obtenerResumen(rango, signal),
    placeholderData: keepPreviousData,
    enabled: listo,
  });
}

export function useVentasPeriodo(rango: RangoFechas, agrupacion: Agrupacion) {
  const listo = useListo();
  return useQuery({
    queryKey: ['reportes', 'ventas-periodo', rango, agrupacion],
    queryFn: ({ signal }) => ventasPorPeriodo(rango, agrupacion, signal),
    placeholderData: keepPreviousData,
    enabled: listo,
  });
}

export function useVentasCategoria(rango: RangoFechas) {
  const listo = useListo();
  return useQuery({
    queryKey: ['reportes', 'ventas-categoria', rango],
    queryFn: ({ signal }) => ventasPorCategoria(rango, signal),
    placeholderData: keepPreviousData,
    enabled: listo,
  });
}

export function useTopProductos(rango: RangoFechas, ordenarPor: OrdenTop) {
  const listo = useListo();
  return useQuery({
    queryKey: ['reportes', 'top-productos', rango, ordenarPor],
    queryFn: ({ signal }) => topProductos(rango, ordenarPor, signal),
    placeholderData: keepPreviousData,
    enabled: listo,
  });
}

export function useCarritosAbandonados(filtros: FiltrosAbandonados) {
  const listo = useListo();
  return useQuery({
    queryKey: ['reportes', 'abandonados', filtros],
    queryFn: ({ signal }) => carritosAbandonados(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: listo,
  });
}