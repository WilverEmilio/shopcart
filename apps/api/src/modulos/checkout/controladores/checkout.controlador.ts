import type { Request, Response, NextFunction } from 'express';
import * as servicio from '../servicios/checkout.servicio';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';

const FORMATO_CLAVE = /^[A-Za-z0-9_-]{8,64}$/;

const leerClaveIdempotencia = (req: Request): string => {
    const valor = req.headers['idempotency-key'];
    if (typeof valor !== 'string' || !FORMATO_CLAVE.test(valor)) {
        throw new ErrorAplicacion(
            'El encabezado Idempotency-Key es obligatorio (8 a 64 caracteres: letras, números, guion o guion bajo).',
            50053, 400);
    }
    return valor;
};

export const listarEnviosControlador = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const datos = await servicio.listarMetodosEnvioServicio();
        res.status(200).json({ mensaje: 'Métodos de envío obtenidos correctamente', datos });
    } catch (error) { next(error); }
};

export const iniciarPagoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { nuevo, pago } = await servicio.iniciarPagoServicio(obtenerIdActor(req), leerClaveIdempotencia(req), req.body);
        res.status(nuevo ? 201 : 200).json({
            mensaje: nuevo ? 'Pago iniciado; existencias reservadas por 15 minutos' : 'Solicitud de pago ya registrada',
            datos: pago
        });
    } catch (error) { next(error); }
};

export const confirmarPagoControlador = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
        const { nuevo, pedido } = await servicio.confirmarPagoServicio(
            obtenerIdActor(req), leerClaveIdempotencia(req), req.body.tokenPago);
        res.status(nuevo ? 201 : 200).json({
            mensaje: nuevo ? 'Pedido creado correctamente' : 'El pedido ya estaba confirmado',
            datos: pedido
        });
    } catch (error) { next(error); }
};