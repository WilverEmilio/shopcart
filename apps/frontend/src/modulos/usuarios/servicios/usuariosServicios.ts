import clienteHttp from "../../../servicios/clienteHttp";
import type {RespuesaApi, Pagina} from '../../../tipos/respuestaApi.ts';
import type { DatosUsuarioNuevo, FiltrosUsuarios, RolSistema, UsuarioAdmin } from "../tipos/usuarioAdmin.ts";

export async function listarUsuarios(
    filtros: FiltrosUsuarios,
    signal?: AbortSignal
){
    const {data} = await clienteHttp.get<RespuesaApi<Pagina<UsuarioAdmin>>>('/usuarios', {
        params: filtros,
        signal
    });
    return data.datos;
}

export async function listarRoles(
    signal?: AbortSignal
): Promise<RolSistema[]> {
    const { data } = await clienteHttp.get<RespuesaApi<Record<string, unknown>[]>>('/usuarios/roles', { 
        signal 
    });
    return data.datos.map((r) => ({
        idRol: Number(r.idRol ?? r.IDRol),
        nombres: String(r.nombre ?? r.Nombre),
    }));
}

export async function crearUsuarioInterno (
    datos: DatosUsuarioNuevo
){
    await clienteHttp.post('/usuarios',datos);
}

export async function cambiarEstadoUsuario(
    idUsuario: number,
    activo: boolean
){
    await clienteHttp.patch(`/usuarios/${idUsuario}/estado`, {
        activo
    });
}