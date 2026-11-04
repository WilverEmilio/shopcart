import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';

export const expirarPagos = async (): Promise<number> => {
  const resultado = await ejecutarProcedimiento<{ PagosExpirados: number }>(
    'dbo.SP_Checkout_ExpirarPagos'
  );
  return resultado.recordset[0]?.PagosExpirados ?? 0;
};