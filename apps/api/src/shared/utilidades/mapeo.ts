const convertirClave = (clave: string): string => {
    if (clave === clave.toUpperCase()) return clave.toLowerCase();           
    return clave.replace(/^ID(?=[A-Z])/, 'id').replace(/^[A-Z]/, c => c.toLowerCase());
};

export const mapearFila = (fila: object): Record<string, unknown> =>
    Object.fromEntries(Object.entries(fila).map(([clave, valor]) => [convertirClave(clave), valor]));

export const mapearFilas = (filas: object[]): Record<string, unknown>[] => filas.map(mapearFila);