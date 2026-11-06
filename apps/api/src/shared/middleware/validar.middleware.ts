import type { Request, Response, NextFunction } from "express";
import type {ZodNaN, ZodType} from 'zod';
import { ErrorAplicacion } from "../errores/error-aplicacion";

interface EsquemaSolicitud {
    params?: ZodType;
    query?: ZodType;
    body?: ZodType;
}

export const validar = (esquemas: EsquemaSolicitud) => (
    solicitud: Request, _respuesta: Response, siguiente: NextFunction
): void => {
    const detalles: {
        campo: string; 
        mensaje: string;
    }  [] = []

    for (const origen of ['params', 'query', 'body'] as const) {
        const esquema = esquemas[origen];
        if (!esquema) continue;

        const resultado = esquema.safeParse(solicitud[origen]);
        
        if (resultado.success){
            Reflect.set(
                solicitud,
                origen,
                resultado.data
            );
        } else {
            for (const problema of resultado.error.issues){
                detalles.push({
                    campo: [origen, ...problema.path].join('.'),
                    mensaje: problema.message
                });
            }
        }
    }

    for (const [origen, esquema] of Object.entries(esquemas)) {
    if (!esquema || typeof (esquema as { safeParse?: unknown }).safeParse !== 'function') {
        throw new Error(`validar(): el esquema de "${origen}" no es un esquema de zod; revisa el import.`);
    }
    }

    if (detalles.length > 0){
        siguiente(new ErrorAplicacion(
            'Los datos enviados no son válidos',
            50053, 
            400,
            detalles
        ));
        return;
    }
    siguiente();
}