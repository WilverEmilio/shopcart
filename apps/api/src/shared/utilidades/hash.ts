import { createHash, randomBytes } from 'crypto';

export const sha256Hex = (valor: string): string =>
    createHash('sha256').update(valor).digest('hex');

export const generarTokenAleatorio = (): string => randomBytes(32).toString('hex');