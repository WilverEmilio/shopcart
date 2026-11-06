import * as servicio from '../servicios/cupones.servicios'
import { manejar } from '../../../shared/utilidades/controlador';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { CuponesQuery } from '../esquemas/cupon.esquema';

export const listarCuponesControlador = manejar(200, 'Cupones obtenidos correctamente',
    req => servicio.listarCuponesServicio(obtenerIdActor(req), req.query as unknown as CuponesQuery));

export const obtenerCuponControlador = manejar(200, 'Cupón obtenido correctamente',
    req => servicio.obtenerCuponServicio(obtenerIdActor(req), Number(req.params.id)));

export const crearCuponControlador = manejar(201, 'Cupón creado correctamente',
    req => {
        const { codigo, ...datos } = req.body;
        return servicio.crearCuponServicio(obtenerIdActor(req), codigo, datos);
    });

export const actualizarCuponControlador = manejar(200, 'Cupón actualizado correctamente',
    req => servicio.actualizarCuponServicio(obtenerIdActor(req), Number(req.params.id), req.body));

export const cambiarEstadoCuponControlador = manejar(200,
    (d: { activo: boolean }) => d.activo ? 'Cupón activado correctamente' : 'Cupón desactivado correctamente',
    req => servicio.cambiarEstadoCuponServicio(obtenerIdActor(req), Number(req.params.id), req.body.activo));

export const eliminarCuponControlador = manejar(200, 'Cupón eliminado correctamente',
    req => servicio.eliminarCuponServicio(obtenerIdActor(req), Number(req.params.id)));