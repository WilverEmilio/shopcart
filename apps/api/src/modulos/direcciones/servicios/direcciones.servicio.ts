import * as repositorio from '../repositorio/direcciones.repositorio';
import { mapearFilas } from '../../../shared/utilidades/mapeo';
import type { DireccionEntrada } from '../tipos/direccion.tipo';

export const listarDireccionesServicio = async (idUsuario: number) =>
    mapearFilas(await repositorio.listarDirecciones(idUsuario));

export const crearDireccionServicio = async (idUsuario: number, datos: DireccionEntrada) =>
    ({ idDireccion: await repositorio.crearDireccion(idUsuario, datos) });

export const actualizarDireccionServicio = async (idUsuario: number, idDireccion: number, datos: DireccionEntrada) => {
    await repositorio.actualizarDireccion(idUsuario, idDireccion, datos);
    return { idDireccion };
};

export const eliminarDireccionServicio = async (idUsuario: number, idDireccion: number) => {
    await repositorio.eliminarDireccion(idUsuario, idDireccion);
    return { idDireccion };
};