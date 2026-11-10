import type {Usuario} from './usuario';

export interface SolicitudInicioSesion {
  correo: string;
  contrasena: string;
}

export interface SolicitudRegistro {
  correo: string;
  contrasena: string;
  nombres: string;
  apellidos: string; 
  telefono?: string | null;
}

export interface RespuestaInicioSesion {
  usuario: Usuario;
  tokenAcceso: string;
  tokenRefresco: string;
}

export interface RespuestaRenovacion {
  usuario: Pick<Usuario, 'idUsuario' | 'correo' | 'rol'>;
  tokenAcceso: string;
  tokenRefresco: string;
}

