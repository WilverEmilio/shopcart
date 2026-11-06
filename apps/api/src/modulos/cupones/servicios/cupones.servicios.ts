import * as repositorio from '../repositorio/cupones.repositorio';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { mapearFila, paginasFilas } from '../../../shared/utilidades/mapeo';
import type { DatosCupon } from '../tipos/cupon.tipo';
import type { CuponesQuery } from '../esquemas/cupon.esquema';

export const listarCuponesServicio = async (idActor: number, q: CuponesQuery) =>
    paginasFilas(await repositorio.listarCupones(idActor, q), q.pagina, q.registrosPorPagina);

export const obtenerCuponServicio = async (idActor: number, idCupon: number) => {
    const fila = await repositorio.obtenerCupon(idActor, idCupon);
    if (!fila) throw new ErrorAplicacion('El cupón no existe.', 50091, 404);
    return mapearFila(fila);
};

export const crearCuponServicio = async (idActor: number, codigo: string, datos: DatosCupon) =>
    ({ idCupon: await repositorio.crearCupon(idActor, codigo, datos) });

export const actualizarCuponServicio = async (idActor: number, idCupon: number, datos: DatosCupon) => {
    await repositorio.actualizarCupon(idActor, idCupon, datos);
    return { idCupon };
};

export const cambiarEstadoCuponServicio = async (idActor: number, idCupon: number, activo: boolean) => {
    const r = await repositorio.cambiarEstadoCupon(idActor, idCupon, activo);
    return { idCupon: r.IDCupon, activo: r.Activo };
};

export const eliminarCuponServicio = async (idActor: number, idCupon: number) => {
    await repositorio.eliminarCupon(idActor, idCupon);
    return { idCupon };
};