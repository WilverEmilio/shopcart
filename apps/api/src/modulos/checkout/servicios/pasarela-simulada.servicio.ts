import { randomUUID } from 'crypto';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';

export type ResultadoCobro =
    | { aprobado: true; referencia: string }
    | { aprobado: false; motivo: string };

const cobros = new Map<string, Promise<ResultadoCobro>>();
const fallosDeRed = new Set<string>();
const reembolsados = new Set<string>();

const esperar = (ms: number) => new Promise<void>(resolver => setTimeout(resolver, ms));

const procesar = async (clave: string, monto: number, tokenPago: string): Promise<ResultadoCobro> => {
    await esperar(300);
    console.log(`[pasarela simulada] cobro de Q${monto.toFixed(2)} con ${tokenPago}`);

    switch (tokenPago) {
        case 'tok_aprobado':
            return { aprobado: true, referencia: `SIM-${randomUUID()}` };
        case 'tok_rechazado':
            return { aprobado: false, motivo: 'Tarjeta rechazada por el banco emisor (simulación).' };
        case 'tok_error_red':
            if (!fallosDeRed.has(clave)) {
                fallosDeRed.add(clave);
                throw new ErrorAplicacion(
                    'La pasarela de pago no respondió; reintente con la misma solicitud.', 50201, 504);
            }
            return { aprobado: true, referencia: `SIM-${randomUUID()}` };
        default:
            return { aprobado: false, motivo: 'Token de pago no reconocido.' };
    }
};

export const cobrar = (clave: string, monto: number, tokenPago: string): Promise<ResultadoCobro> => {
    const previo = cobros.get(clave);
    if (previo) return previo;                      

    const promesa = procesar(clave, monto, tokenPago).catch(error => {
        cobros.delete(clave);                        
        throw error;
    });
    cobros.set(clave, promesa);
    return promesa;
};

export const reembolsar = async (referencia: string): Promise<void> => {
    if (reembolsados.has(referencia)) return;
    reembolsados.add(referencia);
    console.log(`[pasarela simulada] reembolso de ${referencia}`);
};