import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type { 
    ProductoDetalle,
    ProductoDetalleBaseDatos,
    ImagenProductoBaseDatos,
    VarianteProductoBaseDatos,
    AtributoVarianteBaseDatos
} from '../tipos/producto-detalle.tipo';

export const obtenerDetalleProducto = async (
    idProducto: number,
    idUsuarioActor: number | null
): Promise<ProductoDetalle | null> => {
    const resultado = await ejecutarProcedimiento<unknown>(
        'dbo.SP_Productos_ObtenerDetalle',
        (solicitud) => {
            solicitud.input('IDProducto', sql.Int, idProducto),
            solicitud.input('IDUsuarioActor', sql.Int, idUsuarioActor);
        }
    );

    const producto = resultado.recordsets[0][0] as | ProductoDetalleBaseDatos | undefined;

    if (!producto){
        return null;
    }

    const imagenes = resultado.recordsets[1] as ImagenProductoBaseDatos[];
    const variantes = resultado.recordsets[2] as VarianteProductoBaseDatos[];
    const atributos = resultado.recordsets[3] as AtributoVarianteBaseDatos[];

    return{
        producto,
        imagenes,
        variantes,
        atributos
    };
};