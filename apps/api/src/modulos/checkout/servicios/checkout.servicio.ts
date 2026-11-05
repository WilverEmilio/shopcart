import * as repositorio from '../repositorio/checkout.repositorio';
import * as pasarela from './pasarela-simulada.servicio';
import { ErrorAplicacion } from '../../../shared/errores/error-aplicacion';
import { mapearFilas } from '../../../shared/utilidades/mapeo';
import type { DatosIniciarPago } from '../tipo/chechout.tipo';

export const listarMetodosEnvioServicio = async () =>
    mapearFilas(await repositorio.listarMetodosEnvio());

export const iniciarPagoServicio = async (idUsuario: number, clave: string, datos: DatosIniciarPago) => {
    const f = await repositorio.iniciarPago(idUsuario, clave, datos);
    return {
        nuevo: f.Nuevo,
        pago: {
            idPago: f.IDPago, estado: f.Estado, idPedido: f.IDPedido,
            idReserva: f.IDReserva, fechaVencimiento: f.FechaVencimiento, total: f.Total
        }
    };
};

export const confirmarPagoServicio = async (idUsuario: number, clave: string, tokenPago: string) => {
    const pago = await repositorio.obtenerPago(idUsuario, clave);

    if (pago.Estado === 'APROBADO') {
        return { nuevo: false, pedido: { idPedido: pago.IDPedido, numeroPedido: pago.NumeroPedido, total: pago.Total } };
    }

    if (pago.Estado !== 'INICIADO') {
        throw new ErrorAplicacion(
            pago.Motivo ?? `El pago está ${pago.Estado.toLowerCase()}; inicie el pago de nuevo.`, 50114, 409);
    }

    const cobro = await pasarela.cobrar(`${idUsuario}:${clave}`, pago.Total, tokenPago);

    if (!cobro.aprobado) {
        await repositorio.rechazarPago(idUsuario, clave, cobro.motivo);
        throw new ErrorAplicacion(cobro.motivo, 40200, 402);
    }

    const resultado = await repositorio.crearPedido(idUsuario, clave, cobro.referencia);

    if (resultado.Estado !== 'APROBADO') {
        await pasarela.reembolsar(cobro.referencia);
        throw new ErrorAplicacion(
            `${resultado.Motivo ?? 'No fue posible confirmar el pedido.'} El cobro fue revertido.`, 50114, 409);
    }

    return {
        nuevo: resultado.Nuevo,
        pedido: { idPedido: resultado.IDPedido, numeroPedido: resultado.NumeroPedido, total: resultado.Total }
    };
};