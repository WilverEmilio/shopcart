import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicios/direcciones.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';

export const listarDireccionesControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.listarDireccionesServicio(obtenerIdActor(req));
        res.status(200).json({ mensaje: 'Direcciones obtenidas correctamente', datos });
    } catch (error) { next(error); }
};

export const crearDireccionControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.crearDireccionServicio(obtenerIdActor(req), req.body);
        res.status(201).json({ mensaje: 'Dirección creada correctamente', datos });
    } catch (error) { next(error); }
};

export const actualizarDireccionControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.actualizarDireccionServicio(obtenerIdActor(req), Number(req.params.id), req.body);
        res.status(200).json({ mensaje: 'Dirección actualizada correctamente', datos });
    } catch (error) { next(error); }
};

export const eliminarDireccionControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.eliminarDireccionServicio(obtenerIdActor(req), Number(req.params.id));
        res.status(200).json({ mensaje: 'Dirección eliminada correctamente', datos });
    } catch (error) { next(error); }
};