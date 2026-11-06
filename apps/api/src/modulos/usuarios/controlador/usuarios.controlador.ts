import * as servicio from '../servicios/usuarios.servicio';
import { manejar } from '../../../shared/utilidades/controlador';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { UsuariosQuery } from '../esquemas/usuario.esquema';

export const listarUsuariosControlador = manejar(200, 'Usuarios obtenidos correctamente',
    req => servicio.listarUsuariosServicio(obtenerIdActor(req), req.query as unknown as UsuariosQuery));

export const listarRolesControlador = manejar(200, 'Roles obtenidos correctamente',
    req => servicio.listarRolesServicio(obtenerIdActor(req)));

export const crearUsuarioInternoControlador = manejar(201, 'Usuario creado correctamente',
    req => servicio.crearUsuarioInternoServicio(obtenerIdActor(req), req.body));

export const cambiarEstadoUsuarioControlador = manejar(200,
    (d: { activo: boolean }) => d.activo ? 'Usuario activado correctamente' : 'Usuario desactivado correctamente',
    req => servicio.cambiarEstadoUsuarioServicio(obtenerIdActor(req), Number(req.params.id), req.body.activo));