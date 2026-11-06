import * as repositorio from '../repositorio/usuarios.repositorio';
import { hashearContrasena } from '../../../shared/utilidades/contrasena';
import { mapearFilas, paginasFilas } from '../../../shared/utilidades/mapeo';
import type { UsuariosQuery } from '../esquemas/usuario.esquema';

export const listarUsuariosServicio = async (idActor: number, q: UsuariosQuery) =>
    paginasFilas(await repositorio.listarUsuarios(idActor, q), q.pagina, q.registrosPorPagina);

export const listarRolesServicio = async (idActor: number) =>
    mapearFilas(await repositorio.listarRoles(idActor));

export const crearUsuarioInternoServicio = async (
    idActor: number,
    d: { correo: string; contrasena: string; nombres: string; apellidos: string; telefono: string | null; rol: string }
) => {
    const { contrasena, ...resto } = d;
    const idUsuario = await repositorio.crearUsuarioInterno(idActor, {
        ...resto,
        passwordHash: await hashearContrasena(contrasena)
    });
    return { idUsuario };
};

export const cambiarEstadoUsuarioServicio = async (idActor: number, idUsuario: number, activo: boolean) => {
    const r = await repositorio.cambiarEstadoUsuario(idActor, idUsuario, activo);
    return { idUsuario: r.IDUsuario, activo: r.Activo };
};