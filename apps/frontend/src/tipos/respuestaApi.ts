export interface RespuesaApi<T> {
  mensaje: string;
  datos: T;
}
export interface Pagina<T>{
  items: T[];
  pagina: number;
  tamanoPagina: number;
  totalRegistros: number;
}