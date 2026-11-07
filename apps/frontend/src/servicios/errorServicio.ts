import axios from 'axios';
import type { ErrorApi } from '../tipos/errorApi';

export function normalizarError(error: unknown): ErrorApi {
  if (axios.isAxiosError(error)) {
    const respuesta = error.response;

    if (respuesta) {
      return {
        mensaje: respuesta.data?.mensaje ?? 'Ha ocurrido un error al procesar la solicitud.',
        codigo: respuesta.data?.codigo,
        detalles: respuesta.data?.detalles,
        estadoHttp: respuesta.status,
      };
    }

    return {
      mensaje:
        error.code === 'ECONNABORTED'
          ? 'La solicitud ha tardado demasiado.'
          : 'No fue posible conectar con el servidor.',
    };
  }

  if (error instanceof Error) return { mensaje: error.message };
  return { mensaje: 'Ha ocurrido un error inesperado.' };
}

export function erroresPorCampo(error: unknown): Record<string, string> {
  const { detalles } = normalizarError(error);
  const resultado: Record<string, string> = {};

  for (const { campo, mensaje } of detalles ?? []) {
    const nombre = campo.replace(/^(body|query|params)\./, '');
    resultado[nombre] ??= mensaje;
  }
  return resultado;
}