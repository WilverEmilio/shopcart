import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type { FilaPaginada } from '../../../shared/utilidades/mapeo';
import type { UsuariosQuery } from '../esquemas/usuario.esquema';

export const listarUsuarios = async (idActor: number, q: UsuariosQuery): Promise<FilaPaginada[]> =>
    (await ejecutarProcedimiento<FilaPaginada>('dbo.SP_Usuarios_Listar', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Busqueda', sql.NVarChar(100), q.busqueda ?? null);
        s.input('IDRol', sql.Int, q.idRol ?? null);
        s.input('Activo', sql.Bit, q.activo ?? null);
        s.input('OrdenarPor', sql.NVarChar(20), q.ordenarPor);
        s.input('Direccion', sql.NVarChar(4), q.direccion);
        s.input('Pagina', sql.Int, q.pagina);
        s.input('TamanoPagina', sql.Int, q.registrosPorPagina);
    })).recordset;

export const listarRoles = async (idActor: number): Promise<Record<string, unknown>[]> =>
    (await ejecutarProcedimiento<Record<string, unknown>>('dbo.SP_Roles_Listar',
        s => { s.input('IDUsuarioActor', sql.Int, idActor); })).recordset;

export const crearUsuarioInterno = async (
    idActor: number,
    d: { correo: string; passwordHash: string; nombres: string; apellidos: string; telefono: string | null; rol: string }
): Promise<number> => {
    const r = await ejecutarProcedimiento<{ IDUsuario: number }>('dbo.SP_Usuarios_CrearUsuarioInterno', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('Correo', sql.NVarChar(255), d.correo);
        s.input('PasswordHash', sql.NVarChar(255), d.passwordHash);
        s.input('Nombres', sql.NVarChar(100), d.nombres);
        s.input('Apellidos', sql.NVarChar(100), d.apellidos);
        s.input('Telefono', sql.NVarChar(20), d.telefono);
        s.input('NombreRol', sql.NVarChar(50), d.rol);
    }, { reintentosDeadlock: 2 });
    return r.recordset[0].IDUsuario;
};

export const cambiarEstadoUsuario = async (idActor: number, idUsuario: number, activo: boolean) => {
    const r = await ejecutarProcedimiento<{ IDUsuario: number; Activo: boolean }>('dbo.SP_Usuarios_CambiarEstado', s => {
        s.input('IDUsuarioActor', sql.Int, idActor);
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('Activo', sql.Bit, activo);
    }, { reintentosDeadlock: 2 });
    return r.recordset[0];
};