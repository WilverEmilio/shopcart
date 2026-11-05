import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicio/pedidos.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { MisPedidosQuery } from '../esquemas/pedido.esquema';

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