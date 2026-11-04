import sql from 'mssql';
import { obtenerConexion } from '../../config/base-de-datos';

const ERROR_DEADLOCK = 1205;

interface OpcionesEjecucion {
  reintentosDeadlock?: number;
}

const esperar = (ms: number) => new Promise<void>(resolver => setTimeout(resolver, ms));

export const ejecutarProcedimiento = async <T = unknown>(
  nombreProcedimiento: string,
  configurar?: (solicitud: sql.Request) => void,
  opciones: OpcionesEjecucion = {}
): Promise<sql.IResult<T>> => {
  const maximoReintentos = opciones.reintentosDeadlock ?? 0;

  for (let intento = 0; ; intento++) {
    try {
      const conexion = await obtenerConexion();
      const solicitud = conexion.request();
      configurar?.(solicitud);
      return await solicitud.execute<T>(nombreProcedimiento);
    } catch (error) {
      const esDeadlock =
        error instanceof sql.RequestError && Number(error.number) === ERROR_DEADLOCK;

      if (!esDeadlock || intento >= maximoReintentos) {
        throw error;
      }
      await esperar(50 + Math.random() * 100 * (intento + 1));
    }
  }
};