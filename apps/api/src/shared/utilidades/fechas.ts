export const aFechaUtc = (valor?: string): Date | null =>
    valor ? new Date(`${valor}T00:00:00.000Z`) : null;
 
export const aFinDeDiaUtc = (valor?: string): Date | null => 
    valor ? new Date(`${valor}T00:00:00.000Z`) : null;
