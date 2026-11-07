import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios';
import entorno from '../configuracion/entorno';
import { useSesionEstado } from '../estados/sesionEstado';
import type { RespuesaApi } from '../tipos/respuestaApi';
import type { RespuestaRenovacion } from '../tipos/autenticacion';

const configuracionBase = {
  baseURL: entorno.apiUrl,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
};

const clienteBase = axios.create(configuracionBase);
const clienteHttp = axios.create(configuracionBase);

const RUTAS_SIN_RENOVACION = [
  '/autenticacion/iniciar-sesion',
  '/autenticacion/registro',
  '/autenticacion/renovar-token',
  '/autenticacion/cerrar-sesion',
];

type ConfiguracionReintentable = InternalAxiosRequestConfig & { _reintentado?: boolean };

let renovacionEnCurso: Promise<string> | null = null;

export function renovarSesion(): Promise<string> {
  if (renovacionEnCurso) return renovacionEnCurso;

  const { tokenRefresco } = useSesionEstado.getState();
  if (!tokenRefresco) return Promise.reject(new Error('No hay sesión que renovar.'));

  renovacionEnCurso = clienteBase
    .post<RespuesaApi<RespuestaRenovacion>>('/autenticacion/renovar-token', { tokenRefresco })
    .then(({ data }) => {
      const { tokenAcceso, tokenRefresco: nuevoRefresco } = data.datos;
      useSesionEstado.getState().actualizarTokens(tokenAcceso, nuevoRefresco);
      return tokenAcceso;
    })
    .catch((error: unknown) => {
      if (axios.isAxiosError(error) && error.response && [400, 401, 409].includes(error.response.status)) {
        useSesionEstado.getState().cerrarSesion();
      }
      throw error;
    })
    .finally(() => {
      renovacionEnCurso = null;
    });

  return renovacionEnCurso;
}

clienteHttp.interceptors.request.use((config) => {
  const token = useSesionEstado.getState().tokenAcceso;
  if (token && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

clienteHttp.interceptors.response.use(
  (respuesta) => respuesta,
  async (error: AxiosError) => {
    const original = error.config as ConfiguracionReintentable | undefined;
    const url = original?.url ?? '';

    const puedeRenovar =
      error.response?.status === 401 &&
      original !== undefined &&
      !original._reintentado &&
      !RUTAS_SIN_RENOVACION.some((ruta) => url.startsWith(ruta)) &&
      useSesionEstado.getState().tokenRefresco !== null;

    if (!puedeRenovar) return Promise.reject(error);

    original._reintentado = true;

    try {
      const tokenNuevo = await renovarSesion();
      original.headers.Authorization = `Bearer ${tokenNuevo}`;
      return clienteHttp(original);
    } catch {
      return Promise.reject(error);
    }
  }
);

export default clienteHttp;