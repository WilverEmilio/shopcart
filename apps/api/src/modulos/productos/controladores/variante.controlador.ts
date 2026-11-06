import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicios/varitantes.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';

type Manejador = (req: Request, res: Response, next: NextFunction) => Promise<void>;

export const crearVarianteControlador: Manejador = async (req, res, next) => {
    try {
        const { sku, precio, atributos } = req.body;
        const r = await servicio.crearVarianteServicio(obtenerIdActor(req), Number(req.params.id), sku, precio, atributos);
        res.status(201).json({ mensaje: 'Variante creada correctamente', datos: { idVariante: r.IDVariante } });
    } catch (error) { next(error); }
};

export const actualizarVarianteControlador: Manejador = async (req, res, next) => {
    try {
        const r = await servicio.actualizarVarianteServicio(obtenerIdActor(req), Number(req.params.id), req.body.sku, req.body.atributos);
        res.status(200).json({ mensaje: 'Variante actualizada correctamente', datos: { idVariante: r.IDVariante } });
    } catch (error) { next(error); }
};

export const cambiarEstadoVarianteControlador: Manejador = async (req, res, next) => {
    try {
        const r = await servicio.cambiarEstadoVarianteServicio(obtenerIdActor(req), Number(req.params.id), req.body.activo);
        res.status(200).json({
            mensaje: r.Activo ? 'Variante activada correctamente' : 'Variante desactivada correctamente',
            datos: { idVariante: r.IDVariante, activo: r.Activo }
        });
    } catch (error) { next(error); }
};

export const cambiarPrecioVarianteControlador: Manejador = async (req, res, next) => {
    try {
        const r = await servicio.cambiarPrecioVarianteServicio(obtenerIdActor(req), Number(req.params.id), req.body.precio);
        res.status(200).json({ mensaje: 'Precio actualizado correctamente', datos: { idVariante: r.IDVariante, precio: r.Precio } });
    } catch (error) { next(error); }
};

export const eliminarVarianteControlador: Manejador = async (req, res, next) => {
    try {
        const r = await servicio.eliminarVarianteServicio(obtenerIdActor(req), Number(req.params.id));
        res.status(200).json({
            mensaje: r.Resultado === 'ELIMINADO' ? 'Variante eliminada correctamente' : 'La variante tenía historial y fue desactivada',
            datos: { idVariante: r.IDVariante, resultado: r.Resultado }
        });
    } catch (error) { next(error); }
};

export const reemplazarImagenesControlador: Manejador = async (req, res, next) => {
    try {
        const r = await servicio.reemplazarImagenesServicio(obtenerIdActor(req), Number(req.params.id), req.body.imagenes);
        res.status(200).json({ mensaje: 'Imágenes actualizadas correctamente', datos: { idProducto: r.IDProducto } });
    } catch (error) { next(error); }
};