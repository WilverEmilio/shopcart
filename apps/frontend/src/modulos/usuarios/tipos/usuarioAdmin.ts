export interface UsuarioAdmin {
    idUsuario: number;
    correo: string;
    nombres: string;
    apellidos: string;
    telefono: string | null;
    activo: boolean;
    fechaCreacion: string;
    idRol: number;
    rol: string;
}

export interface RolSistema {
    idRol: number;
    nombres: string;
}

export interface FiltrosUsuarios {
    busqueda?: string;
    idRol?: number;
    activo?:  boolean;
    ordenarPor?: 'Correo' | 'Nombre' |'FechaCreacion'; 
    direccion?: 'ASC' | 'DESC';
    pagina?: number;
    registroPorPagina?: number;
}

export type RolInterno = 'Operador' | 'Administrador';

export interface DatosUsuarioNuevo {
    correo: string; 
    contrasena: string;
    nombres: string;
    apellidos: string;
    telefono: string | null;
    rol: RolInterno;
}

export interface UsuarioFormulario {
    correo: string;
    contrasena: string;
    nomrbes: string;
    apellidos: string;
    telefono: string;
    rol: RolInterno;
}