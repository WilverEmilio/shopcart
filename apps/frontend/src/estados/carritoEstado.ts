import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import type { AjusteFusion } from '../modulos/carrito/tipos/carrito';

interface CarritoEstado {
  tokenCarrito: string | null;
  ajustesFusion: AjusteFusion[];

  establecerToken: (token: string) => void;
  limpiarToken: () => void;
  establecerAjustes: (ajustes: AjusteFusion[]) => void;
  limpiarAjustes: () => void;
}

export const useCarritoEstado = create<CarritoEstado>()(
  persist(
    (set) => ({
      tokenCarrito: null,
      ajustesFusion: [],

      establecerToken: (tokenCarrito) => set({ tokenCarrito }),
      limpiarToken: () => set({ tokenCarrito: null }),
      establecerAjustes: (ajustesFusion) => set({ ajustesFusion }),
      limpiarAjustes: () => set({ ajustesFusion: [] }),
    }),
    {
      name: 'shopcart.carrito',
      storage: createJSONStorage(() => localStorage),
      partialize: (estado) => ({ tokenCarrito: estado.tokenCarrito }),
    }
  )
);