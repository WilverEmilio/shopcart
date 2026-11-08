export interface Direccion {
    idDireccion: number;
    nombreDestinatario: string;
    telefono: string;
    departamento: string;
    municipio: string;
    direccion: string;
    referencia: string | null;
    esPredeterminada: boolean;
}

export interface DatosDireccion {
    nombreDestinatario: string;
    telefono: string;
    departamento: string;
    municipio: string;
    direccion: string;
    referencia: string | null;
    esPredeterminada: boolean;
}