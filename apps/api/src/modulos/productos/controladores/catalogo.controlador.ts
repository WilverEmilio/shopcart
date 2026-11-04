import type { Request, Response, NextFunction } from 'express';
import { obtenerCatalogo } from '../servicios/catalogo.servicio';
import type { FiltrosCatalogo } from '../tipos/catalogo.tipo';
import { CatalogoQuery } from '../esquemas/catalogo.esquema';


export const listarProductosControlador = async (
    req: Request, 
    res: Response, 
    next: NextFunction
): Promise<void> => {
    try {
        const q = req.query as unknown as CatalogoQuery;
        const filtros: FiltrosCatalogo = {
            texto: q.texto,
            idCategoria: q.idCategoria,
            precioMin: q.precioMinimo,
            precioMax: q.precioMaximo,
            soloDisponibles: q.soloDisponibles,
            activo: q.activo,
            ordenarPor: q.ordenarPor,
            direccion: q.direccion,
            pagina: q.pagina,
            tamanoPagina: q.registrosPorPagina
        };
        const resultado = await obtenerCatalogo(filtros, req.usuarioAutenticado?.idUsuario ?? null);
        res.status(200).json({ mensaje: 'Catálogo obtenido correctamente', datos: resultado });
    } catch (error) { next(error); }
};