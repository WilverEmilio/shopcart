import type { ReactNode } from 'react';
import type { UseQueryResult } from '@tanstack/react-query';
import { EstadoCarga } from './EstadoCarga';
import { EstadoError } from './EstadoError';
import { EstadoVacio } from './EstadoVacio';

interface Propiedades<T> {
  consulta: UseQueryResult<T, Error>;
  estaVacio?: (datos: T) => boolean;
  mensajeVacio?: string;
  children: (datos: T) => ReactNode;
}

export function BloqueConsulta<T>({
  consulta,
  estaVacio,
  mensajeVacio = 'No hay datos en el periodo seleccionado.',
  children,
}: Propiedades<T>) {
  if (consulta.isPending) return <EstadoCarga />;
  if (consulta.isError) return <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />;
  if (estaVacio?.(consulta.data)) return <EstadoVacio titulo="Sin datos" descripcion={mensajeVacio} />;
  return <>{children(consulta.data)}</>;
}