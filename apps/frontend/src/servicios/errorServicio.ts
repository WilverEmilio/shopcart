
import axios from "axios";
import type { ErrorApi } from "../tipos/errorApi";

export function normalizarError(error: unknown): ErrorApi {
  if (axios.isAxiosError(error)) {
    const respuesta = error.response;

    if (respuesta) {
      return {
        mensaje:
          respuesta.data?.mensaje ??
          "Ha ocurrido un error al procesar la solicitud.",
        codigo: respuesta.data?.codigo,
        errores: respuesta.data?.errores,
        estadoHttp: respuesta.status,
      };
    }

    return {
      mensaje: error.code === "ECONNABORTED"
        ? "La solicitud ha tardado demasiado."
        : "No fue posible conectar con el servidor.",
    };
  }

  if (error instanceof Error) {
    return {
      mensaje: error.message,
    };
  }

  return {
    mensaje: "Ha ocurrido un error inesperado.",
  };
}
