import clienteHttp, { renovarSesion } from '../../../servicios/clienteHttp';
import { clienteQuery } from '../../../configuracion/clienteQuery';
import { useSesionEstado } from '../../../estados/sesionEstado';
import type {
  RespuestaInicioSesion,
  SolicitudInicioSesion,
  SolicitudRegistro,
} from '../../../tipos/autenticacion';
import type { RespuesaApi } from '../../../tipos/respuestaApi';
import type { Perfil, Usuario } from '../../../tipos/usuario';
import { CLAVE_CARRITO } from '../../carrito/constantes';
import { fusionarCarritoInvitado } from '../../carrito/servicios/carritoServicio';

export async function iniciarSesion(credenciales: SolicitudInicioSesion): Promise<Usuario> {
  const { data } = await clienteHttp.post<RespuesaApi<RespuestaInicioSesion>>(
    '/autenticacion/iniciar-sesion',
    credenciales
  );
  const { usuario, tokenAcceso, tokenRefresco } = data.datos;

  clienteQuery.clear();
  const fusion = usuario.rol === 'Cliente' ? await fusionarCarritoInvitado(tokenAcceso) : null;

  useSesionEstado.getState().establecerSesion(tokenAcceso, tokenRefresco, usuario);
  if (fusion) clienteQuery.setQueryData(CLAVE_CARRITO, fusion.carrito);

  return usuario;
}

export async function registrarCliente(datos: SolicitudRegistro): Promise<void> {
  await clienteHttp.post('/autenticacion/registro', datos);
}

export async function obtenerPerfil(): Promise<Perfil> {
  const { data } = await clienteHttp.get<RespuesaApi<Perfil>>('/autenticacion/perfil');
  return data.datos;
}

export async function cerrarSesion(): Promise<void> {
  const { tokenRefresco } = useSesionEstado.getState();

  try {
    if (tokenRefresco) {
      await clienteHttp.post('/autenticacion/cerrar-sesion', { tokenRefresco });
    }
  } catch {
  } finally {
    useSesionEstado.getState().cerrarSesion();
    clienteQuery.clear();
  }
}

let restauracion: Promise<void> | null = null;

export function restaurarSesion(): Promise<void> {
  restauracion ??= (async () => {
    try {
      if (useSesionEstado.getState().tokenRefresco) {
        await renovarSesion();
        const perfil = await obtenerPerfil();
        useSesionEstado.getState().establecerUsuario(perfil);
      }
    } catch {
    } finally {
      useSesionEstado.getState().marcarInicializada();
    }
  })();

  return restauracion;
}