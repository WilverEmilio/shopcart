import bcrypt from 'bcrypt';

const RONDAS_BCRYPT = 10;

export const hashearContrasena = (contrasena: string): Promise<string> =>
    bcrypt.hash(contrasena, RONDAS_BCRYPT);