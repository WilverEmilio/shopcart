import type { Request, RequestHandler } from 'express';

export const manejar = <T>(
    estado: number,
    mensaje: string | ((datos: T) => string),
    accion: (req: Request) => Promise<T>
): RequestHandler =>
    async (req, res, next) => {
        try {
            const datos = await accion(req);
            res.status(estado).json({
                mensaje: typeof mensaje === 'function' ? mensaje(datos) : mensaje,
                datos
            });
        } catch (error) {
            next(error);
        }
    };