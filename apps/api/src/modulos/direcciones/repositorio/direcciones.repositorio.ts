import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type { DireccionBaseDatos, DireccionEntrada } from '../tipos/direccion.tipo';

const aplicarDatos = (s: sql.Request, idUsuario: number, d: DireccionEntrada): void => {
    s.input('IDUsuario', sql.Int, idUsuario);
    s.input('NombreDestinatario', sql.NVarChar(100), d.nombreDestinatario);
    s.input('Telefono', sql.NVarChar(20), d.telefono);
    s.input('Departamento', sql.NVarChar(50), d.departamento);
    s.input('Municipio', sql.NVarChar(50), d.municipio);
    s.input('Direccion', sql.NVarChar(250), d.direccion);
    s.input('Referencia', sql.NVarChar(250), d.referencia);
    s.input('EsPredeterminada', sql.Bit, d.esPredeterminada);
};

export const listarDirecciones = async (
    idUsuario: number
): Promise<DireccionBaseDatos[]> => {
    const r = await ejecutarProcedimiento<DireccionBaseDatos>(
        'dbo.SP_Direcciones_Listar',
        s => { s.input('IDUsuario', sql.Int, idUsuario); 
        });
    return r.recordset;
};

export const crearDireccion = async (
    idUsuario: number, datos: DireccionEntrada
): Promise<number> => {
    const r = await ejecutarProcedimiento<{ IDDireccion: number }>(
        'dbo.SP_Direcciones_Crear',
        s => aplicarDatos(s, idUsuario, datos), { reintentosDeadlock: 2 
        });
    return r.recordset[0].IDDireccion;
};

export const actualizarDireccion = async (
    idUsuario: number, idDireccion: number, datos: DireccionEntrada
): Promise<void> => {
    await ejecutarProcedimiento(
        'dbo.SP_Direcciones_Actualizar', s => {
        aplicarDatos(s, idUsuario, datos);
        s.input('IDDireccion', sql.Int, idDireccion);
    }, { reintentosDeadlock: 2 
    }
);
};

export const eliminarDireccion = async (
    idUsuario: number, idDireccion: number
): Promise<void> => {
    await ejecutarProcedimiento(
        'dbo.SP_Direcciones_Eliminar', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('IDDireccion', sql.Int, idDireccion);
    }, { reintentosDeadlock: 2 }
);
};