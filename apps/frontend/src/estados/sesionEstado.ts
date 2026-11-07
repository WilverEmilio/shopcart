import {create} from 'zustand';
import { createJSONStorage, persist} from 'zustand/middleware';
import type { Usuario } from '../tipos/usuario';

interface SesionEstado{
  tokenAcceso: string | null;
  tokenRefresco: string | null;
  usuario: Usuario | null;
  inicializada: boolean;

  establecerSesion: (tokenAcceso: string, tokenRefresco: string, usuario: Usuario) => void;
  actualizarTokens: (tokenAcceso: string, tokenRefresco: string) => void;
  establecerUsuario: (usuario: Usuario) => void;
  cerrarSesion: () => void;
  marcarInicializada: () => void;
}

export const useSesionEstado = create<SesionEstado>()(
  persist(
    (set) => ({
      tokenAcceso: null,
      tokenRefresco: null,
      usuario: null,
      inicializada: false,

      establecerSesion: (tokenAcceso, tokenRefresco, usuario) =>
        set({ tokenAcceso, tokenRefresco, usuario }),
      actualizarTokens: (tokenAcceso, tokenRefresco) =>
        set({ tokenAcceso, tokenRefresco }),
      establecerUsuario: (usuario) => set({ usuario }),
      cerrarSesion: () =>
        set({ tokenAcceso: null, tokenRefresco: null, usuario: null }),
      marcarInicializada: () => set({ inicializada: true }),
    }),
    {
      name: 'shopcart.sesion',
      storage: createJSONStorage(() => localStorage),
      partialize: (estado) => ({ tokenRefresco: estado.tokenRefresco }),
    }
  )
);