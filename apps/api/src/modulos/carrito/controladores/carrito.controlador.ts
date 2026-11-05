import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicio/carrito.servicio';
import { sha256Hex } from '../../../shared/utilidades/hash';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import type { IdentidadCarrito } from '../tipos/carrito.tipo';

const ENCABEZADO_TOKEN = 'x-carrito-token';
const FORMATO_TOKEN = /^[0-9a-f]{64}$/;

const leerTokenInvitado = (req: Request): string | null => {
    const valor = req.headers[ENCABEZADO_TOKEN];
    if (valor === undefined) return null;
    if (typeof valor !== 'string' || !FORMATO_TOKEN.test(valor)) {
        throw new ErrorAplicacion('El token del carrito no es válido.', 50053, 400);
    }
    return valor;
};

// Con sesión, el carrito es del usuario; sin sesión, el del token (si lo hay)
const resolverIdentidad = (req: Request): IdentidadCarrito => {
    if (req.usuarioAutenticado) {
        return { idUsuario: req.usuarioAutenticado.idUsuario, tokenHash: null };
    }
    const token = leerTokenInvitado(req);
    return { idUsuario: null, tokenHash: token ? sha256Hex(token) : null };
};

export const obtenerCarritoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.obtenerCarritoServicio(resolverIdentidad(req));
        res.status(200).json({ mensaje: 'Carrito obtenido correctamente', datos });
    } catch (error) { next(error); }
};

export const agregarItemControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.agregarProductoServicio(
            resolverIdentidad(req), req.body.idVariante, req.body.cantidad
        );
        res.status(200).json({ mensaje: 'Producto agregado al carrito', datos });
    } catch (error) { next(error); }
};

export const actualizarCantidadControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.actualizarCantidadServicio(
            resolverIdentidad(req), Number(req.params.idVariante), req.body.cantidad
        );
        res.status(200).json({ mensaje: 'Cantidad actualizada', datos });
    } catch (error) { next(error); }
};

export const eliminarItemControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.eliminarProductoServicio(
            resolverIdentidad(req), Number(req.params.idVariante)
        );
        res.status(200).json({ mensaje: 'Producto eliminado del carrito', datos });
    } catch (error) { next(error); }
};

export const fusionarCarritoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const token = leerTokenInvitado(req);
        if (!token) {
            throw new ErrorAplicacion('Falta el token del carrito de invitado.', 50080, 400);
        }
        const datos = await servicio.fusionarCarritoServicio(obtenerIdActor(req), sha256Hex(token));
        res.status(200).json({ mensaje: 'Carritos fusionados', datos });
    } catch (error) { next(error); }
};

export const aplicarCuponControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.aplicarCuponServicio(obtenerIdActor(req), req.body.codigo);
        res.status(200).json({ mensaje: 'Cupón aplicado', datos });
    } catch (error) { next(error); }
};

export const quitarCuponControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.quitarCuponServicio(obtenerIdActor(req));
        res.status(200).json({ mensaje: 'Cupón retirado', datos });
    } catch (error) { next(error); }
};