export interface UsuarioBaseDatos {
    IDUsuario: number;
    Correo: string;
    PasswordHash: string;
    Nombres: string;
    Apellidos: string; 
    Activo: boolean;
    IDRol: number;
    Rol: string;
}

export interface CredencialesAcceso {
    correo: string
    contrasena: string;
}

export interface DatosToken {
    idUsuario: number;
    correo: string;
    rol: string;
}

export interface UsuarioDetalleBaseDatos {
    IDUsuario: number;
    Correo: string;
    Nombres: string;
    Apellidos: string;
    Telefono: string | null;
    Activo: boolean;
    FechaCreacion: Date;
    IDRol: number;
    Rol: string;
}

export interface DatosRegistroCliente {
    correo: string;
    passwordHash: string;
    nombres: string;
    apellidos: string;
    telefono: string | null;
}

export interface UsuarioTokenBaseDatos {
    IDUsuario: number; 
    Correo: string;
    Rol: string;
}

export interface TokenGuardadoBaseDatos {
    IDTokenRefresco: number;
}