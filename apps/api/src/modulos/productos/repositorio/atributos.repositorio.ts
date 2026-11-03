import { ejecutarProcedimiento } from '../../../shared/base_de_datos/ejecutar-procedimiento';
import { AtributoBaseDatos } from '../tipos/atributo.tipo';

export const listarAtributos = async (): Promise<AtributoBaseDatos[]> => {
  const resultado = await ejecutarProcedimiento<AtributoBaseDatos>(
    'dbo.SP_Atributos_Listar'
  );

  return resultado.recordset;
};