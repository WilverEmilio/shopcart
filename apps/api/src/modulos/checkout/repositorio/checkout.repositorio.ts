import sql from 'mssql';
import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import type {
    DatosIniciarPago, PagoBaseDatos, IniciarPagoBaseDatos, CrearPedidoBaseDatos, MetodoEnvioBaseDatos
} from '../tipo/chechout.tipo';

const REINTENTOS = { reintentosDeadlock: 2 };

export const listarMetodosEnvio = async (): Promise<MetodoEnvioBaseDatos[]> =>
    (await ejecutarProcedimiento<MetodoEnvioBaseDatos>('dbo.SP_Envios_Listar')).recordset;

export const iniciarPago = async (idUsuario: number, clave: string, datos: DatosIniciarPago): Promise<IniciarPagoBaseDatos> => {
    const r = await ejecutarProcedimiento<IniciarPagoBaseDatos>('dbo.SP_Checkout_IniciarPago', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('ClaveIdempotencia', sql.NVarChar(64), clave);
        s.input('IDDireccion', sql.Int, datos.idDireccion);
        s.input('IDMetodoEnvio', sql.Int, datos.idMetodoEnvio);
        s.input('TotalEsperado', sql.Decimal(18, 2), datos.totalEsperado ?? null);
    }, REINTENTOS);
    return r.recordset[0];
};

export const obtenerPago = async (idUsuario: number, clave: string): Promise<PagoBaseDatos> => {
    const r = await ejecutarProcedimiento<PagoBaseDatos>('dbo.SP_Checkout_Obtener_Pago', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('ClaveIdempotencia', sql.NVarChar(64), clave);
    });
    return r.recordset[0];
};

export const crearPedido = async (idUsuario: number, clave: string, referencia: string): Promise<CrearPedidoBaseDatos> => {
    const r = await ejecutarProcedimiento<CrearPedidoBaseDatos>('dbo.SP_Pedidos_CrearPedido', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('ClaveIdempotencia', sql.NVarChar(64), clave);
        s.input('ReferenciaPasarela', sql.NVarChar(100), referencia);
    }, REINTENTOS);
    return r.recordset[0];
};

export const rechazarPago = async (idUsuario: number, clave: string, motivo: string): Promise<void> => {
    await ejecutarProcedimiento('dbo.SP_Checkout_RechazarPago', s => {
        s.input('IDUsuario', sql.Int, idUsuario);
        s.input('ClaveIdempotencia', sql.NVarChar(64), clave);
        s.input('Motivo', sql.NVarChar(255), motivo);
    }, REINTENTOS);
};