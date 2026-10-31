import sql from 'mssql'; 
import { obtenerConexion } from '../config/base-de-datos';

export const ejecutarProcedimiento = async <T = unknown>(
  nombreProcedimiento: string,
  configurar?: (solicitud: sql.Request) => void
): Promise<sql.IResult<T>> => {
  const conexion = await obtenerConexion();

  const solicitud = conexion.request();

  configurar?.(solicitud);

  return solicitud.execute<T>(nombreProcedimiento);
};