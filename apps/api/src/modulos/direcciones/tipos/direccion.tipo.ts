export interface DireccionEntrada {
    nombreDestinatario: string;
    telefono: string;
    departamento: string;
    municipio: string;
    direccion: string
    referencia: string | null, 
    esPredeterminada: boolean;
}

export interface DireccionBaseDatos {
    IDDireccion: number;
    NombreDestinatario: string;
    Telefono: string; 
    Departamento: string;
    Municipio: string;
    Direccion: string;
    Referencia: string | null;
    EsPredeterminada: boolean;
}