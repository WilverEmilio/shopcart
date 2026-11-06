import { listarBitacora } from '../repositorio/bitacora.repositorio';
import { paginasFilas } from '../../../shared/utilidades/mapeo';
import type { BitacoraQuery } from '../esquemas/bitacora.esquema';

// La BD guarda los valores como JSON en texto; se entregan ya como objetos
const analizar = (valor: unknown): unknown => {
    if (typeof valor !== 'string') return null;
    try { return JSON.parse(valor); } catch { return valor; }
};

export const listarBitacoraServicio = async (idActor: number, q: BitacoraQuery) => {
    const pagina = paginasFilas(await listarBitacora(idActor, q), q.pagina, q.registrosPorPagina);
    return {
        ...pagina,
        items: pagina.items.map(i => ({
            ...i,
            valorAnterior: analizar(i.valorAnterior),
            valorNuevo: analizar(i.valorNuevo)
        }))
    };
};