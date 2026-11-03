
import clienteHttp from "../../../servicios/clienteHttp";
import { useSesionEstado } from "../../../estados/sesionEstado";

import type {
  SolicitudInicioSesion,
  RespuestaInicioSesion,
} from "../../../tipos/autenticacion";

import type { RespuestaApi } from "../../../tipos/respuestaApi";

export async function iniciarSesion(
  credenciales: SolicitudInicioSesion
) {
  const respuesta = await clienteHttp.post<
    RespuestaApi<RespuestaInicioSesion>
  >("/autenticacion/iniciar-sesion", credenciales);

  const { tokenAcceso, usuario } = respuesta.data.datos;

  useSesionEstado.getState().establecerSesion(
    tokenAcceso,
    usuario
  );

  return usuario;
}

export async function cerrarSesion() {
  try {
    await clienteHttp.post("/autenticacion/cerrar-sesion");
  } finally {
    useSesionEstado.getState().cerrarSesion();
  }
}
