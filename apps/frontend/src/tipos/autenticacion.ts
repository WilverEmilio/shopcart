import type {Usuario} from './usuario';

export interface SolicitudInicioSesion {
  correo: string;
  contrasena: string;
}

export interface SolicitudRegistro {
  correo: string;
  contrasena: String;
  nombres: String;
  apellidos: String; 
  telefono?: String | null;
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

