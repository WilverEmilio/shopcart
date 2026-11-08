import { useEffect, useState } from 'react';

const MAXIMO_RESERVA_MS = 15 * 60 * 1000;

const restanteHasta = (fecha: string | null): number => {
  if (!fecha) return 0;
  return Math.min(Math.max(new Date(fecha).getTime() - Date.now(), 0), MAXIMO_RESERVA_MS);
};

export function useCuentaRegresiva(fechaVencimiento: string | null): number {
  const [restante, setRestante] = useState(() => restanteHasta(fechaVencimiento));

  useEffect(() => {
    const id = window.setInterval(() => setRestante(restanteHasta(fechaVencimiento)), 1000);
    return () => window.clearInterval(id);
  }, [fechaVencimiento]);

  return restante;
}