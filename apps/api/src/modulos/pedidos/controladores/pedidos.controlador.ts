import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicio/pedidos.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { ListarPedidosQuery, MisPedidosQuery } from '../esquemas/pedido.esquema';

export const listarMisPedidosControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const q = req.query as unknown as MisPedidosQuery;
        const datos = await servicio.listarMisPedidosServicio(obtenerIdActor(req), q.estado, q.pagina, q.registroPorPagina);
        res.status(200).json({ mensaje: 'Pedidos obtenidos correctamente', datos });
    } catch (error) { next(error); }
};

export const obtenerDetallePedidoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.obtenerDetallePedidoServicio(obtenerIdActor(req), Number(req.params.id));
        res.status(200).json({ mensaje: 'Pedido obtenido correctamente', datos });
    } catch (error) { next(error); }
};

export const cancelarPedidoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.cancelarPedidoServicio(obtenerIdActor(req), Number(req.params.id), req.body.motivo);
        res.status(200).json({ mensaje: datos.cambio ? 'Pedido cancelado correctamente' : 'El pedido ya estaba cancelado', datos });
    } catch (error) { next(error); }
};

export const listarPedidosControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.listarPedidosServicio(obtenerIdActor(req), req.query as unknown as ListarPedidosQuery);
        res.status(200).json({ mensaje: 'Pedidos obtenidos correctamente', datos });
    } catch (error) { next(error); }
};

export const avanzarEstadoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.avanzarEstadoServicio(
            obtenerIdActor(req), Number(req.params.id), req.body.estado, req.body.comentario);
        res.status(200).json({ mensaje: datos.cambio ? 'Estado actualizado correctamente' : 'El pedido ya estaba en ese estado', datos });
    } catch (error) { next(error); }
};

export const registrarDevolucionControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.registrarDevolucionServicio(obtenerIdActor(req), Number(req.params.id), req.body);
        res.status(201).json({ mensaje: 'Devolución registrada correctamente', datos });
    } catch (error) { next(error); }
};

export const listarTransicionesControlador = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        res.status(200).json({ mensaje: 'Transiciones obtenidas correctamente', datos: await servicio.listarTransicionesServicio() });
    } catch (error) { next(error); }
};