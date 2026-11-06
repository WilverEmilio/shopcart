import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicio/inventario.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { ExistenciasQuery, KardexQuery, ConciliacionQuery } from '../esquemas/inventario.esquema';

export const listarExistenciasControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.listarExistenciasServicio(obtenerIdActor(req), req.query as unknown as ExistenciasQuery);
        res.status(200).json({ mensaje: 'Existencias obtenidas correctamente', datos });
    } catch (error) { next(error); }
};

export const listarKardexControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.listarKardexServicio(obtenerIdActor(req), req.query as unknown as KardexQuery);
        res.status(200).json({ mensaje: 'Kardex obtenido correctamente', datos });
    } catch (error) { next(error); }
};

export const obtenerConciliacionControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.obtenerConciliacionServicio(obtenerIdActor(req), req.query as unknown as ConciliacionQuery);
        res.status(200).json({ mensaje: 'Conciliación obtenida correctamente', datos });
    } catch (error) { next(error); }
};

export const registrarEntradaControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.registrarEntradaServicio(obtenerIdActor(req), req.body);
        res.status(201).json({ mensaje: 'Entrada registrada correctamente', datos });
    } catch (error) { next(error); }
};

export const registrarAjusteControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.registrarAjusteServicio(obtenerIdActor(req), req.body);
        res.status(201).json({ mensaje: 'Ajuste registrado correctamente', datos });
    } catch (error) { next(error); }
};