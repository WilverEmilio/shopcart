import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { EstadoCarga } from '../componentes/EstadoCarga';
import { useSesionEstado } from '../estados/sesionEstado';
import type { RolUsuario } from '../tipos/usuario';

interface Propiedades {
  rolesPermitidos?: RolUsuario[];
}

export function RutasProtegidas({ rolesPermitidos }: Propiedades) {
  const usuario = useSesionEstado((e) => e.usuario);
  const inicializada = useSesionEstado((e) => e.inicializada);
  const ubicacion = useLocation();

  if (!inicializada) return <EstadoCarga mensaje="Verificando sesión..." />;

  if (!usuario) {
    return <Navigate to="/iniciar-sesion" replace state={{ desde: ubicacion.pathname }} />;
  }

  if (rolesPermitidos && !rolesPermitidos.includes(usuario.rol)) {
    return <Navigate to="/sin-permiso" replace />;
  }

  return <Outlet />;
}