
import { create } from "zustand";
import type { Usuario } from "../tipos/usuario";

interface SesionEstado {
  tokenAcceso: string | null;
  usuario: Usuario | null;

  establecerSesion: (
    token: string,
    usuario: Usuario
  ) => void;

  cerrarSesion: () => void;
}

export const useSesionEstado = create<SesionEstado>((set) => ({
  tokenAcceso: null,
  usuario: null,

  establecerSesion: (token, usuario) => {
    set({
      tokenAcceso: token,
      usuario,
    });
  },

  cerrarSesion: () => {
    set({
      tokenAcceso: null,
      usuario: null,
    });
  },
}));
