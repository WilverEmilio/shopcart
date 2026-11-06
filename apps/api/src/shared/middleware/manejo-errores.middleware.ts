import {
    Request,
    Response,
    NextFunction
} from 'express';

import sql from 'mssql';
import { ErrorAplicacion } from '../errores/error-aplicacion';
import { catalogoErrores } from '../errores/catalogo-errores';
import { env } from '../../config/env';

export const manejoErroresMiddleware = (
    error: unknown,
    _solicitud: Request,
    respuesta: Response, 
    _siguiente: NextFunction
    
): void => {


    if (error instanceof SyntaxError && 'body' in error) {
        respuesta.status(400).json({
            codigo: 40000,
            mensaje: 'El cuerpo de la solicitud no es un JSON válido'
        });
        return;
    }

    if (error instanceof ErrorAplicacion) {
        respuesta.status(error.estadoHTTP).json({
            codigo: error.codigo,
            mensaje: error.estadoHTTP >= 500
                ? 'Ocurrió un error interno en el servidor'
                : error.message,
            detalles: error.detalles
        });
        return;
    }

    if (error instanceof sql.RequestError) {
        if (env.nodeEnv === 'development') {
            console.warn(
                `[SQL ${error.number}] ${error.procName ?? '(sin SP)'} línea ${error.lineNumber}: ${error.message}`
            );
        }

        const codigoSQL = Number(error.number);
        const estadoHTTP = catalogoErrores[codigoSQL];

        if (estadoHTTP) {
            if (estadoHTTP >= 500) {
                console.error('Error SQL de negocio:', error);
            }

            respuesta.status(estadoHTTP).json({
                codigo: codigoSQL,
                mensaje: estadoHTTP >= 500
                    ? 'Ocurrió un error interno en el servidor'
                    : error.message
            });
            return;
        }

        switch (codigoSQL) {
            case 1205:
            case 1222:
                respuesta.status(503).json({
                    codigo: codigoSQL,
                    mensaje: 'El servicio está temporalmente ocupado. Intente nuevamente'
                });
                return;
            case 2601:
            case 2627:
                respuesta.status(409).json({
                    codigo: codigoSQL,
                    mensaje: 'El registro ya existe'
                });
                return;
            case 8152:
            case 245:
            case 8114:
                respuesta.status(400).json({
                    codigo: codigoSQL,
                    mensaje: 'Los datos proporcionados no son válidos'
                });
                return;
        }
    }

    console.error('Error no controlado:', error);

    respuesta.status(500).json({
        codigo: 50000,
        mensaje: 'Ocurrió un error interno en el servidor'
    });
};