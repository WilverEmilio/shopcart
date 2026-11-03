import { listarAtributos } from '../repositorio/atributos.repositorio';
import { AtributoBaseDatos } from '../tipos/atributo.tipo';

export const listarAtributosServicio = async (): Promise<AtributoBaseDatos[]> => {
  return await listarAtributos();
};