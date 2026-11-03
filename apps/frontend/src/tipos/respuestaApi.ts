
export interface RespuestaApi<T> {
  exitoso: boolean;
  mensaje: string;
  datos: T;
}
