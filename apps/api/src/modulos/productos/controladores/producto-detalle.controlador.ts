import type { Request, Response, NextFunction } from "express";
import { ObtenerDetalleProductoServicio } from "../servicios/producto-detalle.servicio";

export const obtenerDetalleProductoControlador = async (
    req: Request,
    res: Response,
    next: NextFunction
): Promise<void> => {
    try {
        const idProducto = Number(req.params.id);

        if(!Number.isInteger(idProducto) || idProducto <= 0){
            res.status(400).json({
                mensaje: 'El identificador del producto no es válido'
            });
            return;
        }
        const idUsuarioActor = req.usuarioAutenticado?.idUsuario ?? null;
        const resultado = await ObtenerDetalleProductoServicio(
            idProducto,
            idUsuarioActor
        );
        res.status(200).json({
            mensaje: 'Detalle del producto obtenido correctamente',
            datos: resultado
        });
    } catch (error){
        next(error);
    }
}