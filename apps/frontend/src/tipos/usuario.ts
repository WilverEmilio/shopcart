export type RolUsuario = 
'Cliente' | 
'Operador' | 
'Administrador';

export interface Usuario {
  idUsuario: number;
  correo: string;
  nombres: string;
  apellidos: string;
  rol: RolUsuario;
}

export interface Perfil extends Usuario {
  telefono: string | null;
}