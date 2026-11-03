
export type RolUsuario =
  | "CLIENTE"
  | "OPERADOR"
  | "ADMINISTRADOR";

export interface Usuario {
  idUsuario: number;
  nombre: string;
  correo: string;
  rol: RolUsuario;
  activo: boolean;
}
