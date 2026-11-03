
import type { Usuario } from "./usuario";

export interface SolicitudInicioSesion {
  correo: string;
  contrasena: string;
}

export interface RespuestaInicioSesion {
  tokenAcceso: string;
  usuario: Usuario;
}

export interface SolicitudRegistro {
  nombre: string;
  correo: string;
  contrasena: string;
}
