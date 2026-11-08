import { obtenerDetalleProducto } from "../repositorio/producto-detalle.respositorio";
import { ErrorAplicacion } from "../../../shared/errores/error-aplicacion";
import {mapearFila, mapearFilas} from '../../../shared/utilidades/mapeo'

export const ObtenerDetalleProductoServicio = async (
    idProducto: number,
    idUsuarioActor: number | null
) => {
    const producto = await obtenerDetalleProducto(
        idProducto,
        idUsuarioActor
    ); 

    if(!producto){
        throw new ErrorAplicacion(
            'Producto no encontrado', 
            50012,
            404
        );
    }
    return {
        producto: mapearFila(producto.producto),
        imagenes: mapearFilas(producto.imagenes),
        variantes: mapearFilas(producto.variantes),
        atributos: mapearFilas(producto.atributos),
    };
}