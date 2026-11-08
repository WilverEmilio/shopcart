import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import type { PagoIniciado } from '../modulos/checkout/tipos/checkout';

interface CheckoutEstado {
  clave: string | null;
  idDireccion: number | null;
  idMetodoEnvio: number | null;
  pago: PagoIniciado | null;

  prepararIntento: (idDireccion: number, idMetodoEnvio: number) => string;
  registrarPago: (pago: PagoIniciado) => void;
  reiniciar: () => void;
}

export const useCheckoutEstado = create<CheckoutEstado>()(
  persist(
    (set, get) => ({
      clave: null,
      idDireccion: null,
      idMetodoEnvio: null,
      pago: null,

      prepararIntento: (idDireccion, idMetodoEnvio) => {
        const actual = get();
        if (actual.clave && actual.idDireccion === idDireccion && actual.idMetodoEnvio === idMetodoEnvio) {
          return actual.clave;
        }
        const clave = `chk-${crypto.randomUUID()}`;
        set({ clave, idDireccion, idMetodoEnvio, pago: null });
        return clave;
      },

      registrarPago: (pago) => set({ pago }),

      reiniciar: () => set({ clave: null, idDireccion: null, idMetodoEnvio: null, pago: null }),
    }),
    {
      name: 'shopcart.checkout',
      storage: createJSONStorage(() => sessionStorage),
      partialize: (e) => ({ clave: e.clave, idDireccion: e.idDireccion, idMetodoEnvio: e.idMetodoEnvio, pago: e.pago }),
    }
  )
);