import clienteHttp from "../../../servicios/clienteHttp";
import type { RespuesaApi } from "../../../tipos/respuestaApi";
import type { DatosDireccion, Direccion } from "../tipos/direccion";

export async function listarDirecciones(
    signal?: AbortSignal
): Promise<Direccion[]>{
    const { data } = await clienteHttp.get<RespuesaApi<Direccion[]>>('/direcciones', { signal });
    return data.datos;
}

export async function crearDireccion(
    datos: DatosDireccion
): Promise<number> {
    const { data } = await clienteHttp.post<RespuesaApi<{ idDireccion: number }>>('/direcciones', datos);
    return data.datos.idDireccion;
}