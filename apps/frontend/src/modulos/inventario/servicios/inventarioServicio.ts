import clienteHttp from "../../../servicios/clienteHttp";
import type { Pagina, RespuesaApi } from "../../../tipos/respuestaApi";
import type {
    DatosMovimiento,
    ExistenciaVariante,
    FilaConciliacion,
    FiltrosExistencias,
    FiltrosConciliacion,
    FiltrosKardex,
    MovimientoKardex,
    ResultadoMovimiento
} from '../tipos/inventario';

export async function listarExistencias(
    filtros: FiltrosExistencias, 
    signal?: AbortSignal
){
    const {data} = await clienteHttp.get<RespuesaApi<Pagina<ExistenciaVariante>>>('/inventario/existencias',{
        params: {
            ...filtros,
            soloSinDisponibilidad: filtros.soloSinDisponibilidad ? true : undefined
        }, signal
    });
    return data.datos
}

export async function listarKardex(
    filtros: FiltrosKardex, 
    signal?: AbortSignal
){
    const {data} = await clienteHttp.get<RespuesaApi<Pagina<MovimientoKardex>>>('/inventario/kardex',{
        params: filtros,
        signal,
    });
    return data.datos;
}

export async function obtenerConciliacion(
    filtros: FiltrosConciliacion, 
    signal?: AbortSignal
) {
  const { data } = await clienteHttp.get<RespuesaApi<Pagina<FilaConciliacion>>>('/inventario/conciliacion', {
    params: filtros,
    signal,
  });
  return data.datos;
}

export async function registrarEntrada(
    datos: DatosMovimiento
) {
  const { data } = await clienteHttp.post<RespuesaApi<ResultadoMovimiento>>('/inventario/entradas', datos);
  return data.datos;
}

export async function registrarAjuste(
    datos: DatosMovimiento
) {
  const { data } = await clienteHttp.post<RespuesaApi<ResultadoMovimiento>>('/inventario/ajustes', datos);
  return data.datos;
}