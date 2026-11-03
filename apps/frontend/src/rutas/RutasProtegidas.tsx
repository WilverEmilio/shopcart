
import { Navigate, Outlet } from "react-router-dom";

import { useSesionEstado } from "../estados/sesionEstado";
import type { RolUsuario } from "../tipos/usuario";

interface Propiedades {
  rolesPermitidos?: RolUsuario[];
}

export function RutasProtegidas({
  rolesPermitidos,
}: Propiedades) {
  const token = useSesionEstado(
    (estado) => estado.tokenAcceso
  );

  const usuario = useSesionEstado(
    (estado) => estado.usuario
  );

  if (!token || !usuario) {
    return <Navigate to="/iniciar-sesion" replace />;
  }

  if (
    rolesPermitidos &&
    !rolesPermitidos.includes(usuario.rol)
  ) {
    return <Navigate to="/sin-permiso" replace />;
  }

  return <Outlet />;
}
