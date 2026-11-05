import * as repositorio from '../repositorio/carrito.repositorio';
import { generarTokenAleatorio, sha256Hex } from '../../../shared/utilidades/hash';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import type { IdentidadCarrito, CarritoResumenBaseDatos, LineaCarritoBaseDatos } from '../tipos/carrito.tipo';

const CARRITO_VACIO = {
    idCarrito: null, subtotal: 0, descuento: 0, total: 0, baseImponible: 0, iva: 0,
    lineas: 0, cupon: null, items: []
};

const mapearCarrito = (resumen: CarritoResumenBaseDatos, lineas: LineaCarritoBaseDatos[]) => ({
    idCarrito: resumen.IDCarrito,
    subtotal: resumen.Subtotal,
    descuento: resumen.Descuento,
    total: resumen.Total,
    baseImponible: resumen.BaseImponible,
    iva: resumen.Iva,
    lineas: resumen.Lineas,
    cupon: resumen.IDCupon === null ? null : {
        idCupon: resumen.IDCupon,
        codigo: resumen.CodigoCupon,
        valido: resumen.CuponRechazo === null,
        mensaje: resumen.CuponMensaje
    },
    items: lineas.map(l => ({
        idVariante: l.IDVariante,
        sku: l.SKU,
        idProducto: l.IDProducto,
        producto: l.Producto,
        atributos: l.Atributos,
        precio: l.Precio,
        cantidad: l.Cantidad,
        subtotal: l.Subtotal,
        disponible: l.Disponible,
        vendible: l.Vendible,
        excedeExistencia: l.ExcedeExistencia,
        imagen: l.ImagenPrincipal
    }))
});

export const obtenerCarritoServicio = async (identidad: IdentidadCarrito) => {
    if (identidad.idUsuario === null && identidad.tokenHash === null) {
        return CARRITO_VACIO;
    }
    const { resumen, lineas } = await repositorio.obtenerCarrito(identidad);
    return mapearCarrito(resumen, lineas);
};

export const agregarProductoServicio = async (
    identidad: IdentidadCarrito, idVariante: number, cantidad: number
) => {
    let tokenNuevo: string | null = null;
    let identidadEfectiva = identidad;

    if (identidad.idUsuario === null && identidad.tokenHash === null) {
        tokenNuevo = generarTokenAleatorio();
        identidadEfectiva = { idUsuario: null, tokenHash: sha256Hex(tokenNuevo) };
    }

    await repositorio.agregarProducto(identidadEfectiva, idVariante, cantidad);
    const carrito = await obtenerCarritoServicio(identidadEfectiva);

    return { ...carrito, tokenCarrito: tokenNuevo };
};

export const actualizarCantidadServicio = async (
    identidad: IdentidadCarrito, idVariante: number, cantidad: number
) => {
    await repositorio.actualizarCantidad(identidad, idVariante, cantidad);
    return obtenerCarritoServicio(identidad);
};

export const eliminarProductoServicio = async (identidad: IdentidadCarrito, idVariante: number) => {
    await repositorio.eliminarProducto(identidad, idVariante);
    return obtenerCarritoServicio(identidad);
};

export const fusionarCarritoServicio = async (idUsuario: number, tokenHash: string) => {
    const { resultado, ajustes } = await repositorio.fusionarCarritos(idUsuario, tokenHash);
    const carrito = await obtenerCarritoServicio({ idUsuario, tokenHash: null });

    return {
        fusionado: resultado.Fusionado,
        ajustes: ajustes.map(a => ({
            idVariante: a.IDVariante, sku: a.SKU, solicitada: a.Solicitada, aplicada: a.Aplicada
        })),
        carrito
    };
};

export const aplicarCuponServicio = async (idUsuario: number, codigo: string) => {
    await repositorio.aplicarCupon(idUsuario, codigo);
    return obtenerCarritoServicio({ idUsuario, tokenHash: null });
};

export const quitarCuponServicio = async (idUsuario: number) => {
    await repositorio.quitarCupon(idUsuario);
    return obtenerCarritoServicio({ idUsuario, tokenHash: null });
};

void ErrorAplicacion;