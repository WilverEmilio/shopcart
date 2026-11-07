import type {FieldValues, Path, UseFormSetError} from 'react-hook-form';
import { erroresPorCampo, normalizarError } from '../servicios/errorServicio';


export function aplicarErrorServidor<T extends FieldValues>(
  error: unknown,
  setError: UseFormSetError<T>,
  camposValidos: readonly Path<T>[]
): string | null {
  const porCampo = erroresPorCampo(error);
  let aplicado = false;

  for (const campo of camposValidos) {
    const mensaje = porCampo[campo];
    if (mensaje) {
      setError(campo, {
         type: 'servidor', 
         message: mensaje 
        });
      aplicado = true;
    }
  }

  return aplicado ? null : normalizarError(error).mensaje;
}