import { useMutation, useQuery } from '@tanstack/react-query';
import { useCheckoutEstado } from '../../../estados/checkoutEstado';
import { confirmarPago, iniciarPago, listarMetodosEnvio } from '../servicios/checkoutServicio';

export function useMetodosEnvio() {
  return useQuery({
    queryKey: ['checkout', 'envios'],
    queryFn: ({ signal }) => listarMetodosEnvio(signal),
    staleTime: 5 * 60_000,
  });
}

export function useIniciarPago() {
  return useMutation({
    mutationFn: (datos: { idDireccion: number; idMetodoEnvio: number; totalEsperado: number }) => {
      const clave = useCheckoutEstado.getState().prepararIntento(datos.idDireccion, datos.idMetodoEnvio);
      return iniciarPago(clave, datos);
    },
    onSuccess: (pago) => useCheckoutEstado.getState().registrarPago(pago),
  });
}

export function useConfirmarPago() {
  return useMutation({
    mutationFn: (tokenPago: string) => {
      const { clave } = useCheckoutEstado.getState();
      if (!clave) throw new Error('No hay un pago iniciado.');
      return confirmarPago(clave, tokenPago);
    },
  });
}