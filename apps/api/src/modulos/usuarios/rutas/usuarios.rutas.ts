import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { idParametroEsquema, cambiarEstadoEsquema } from '../../../shared/esquemas/comunes.esquema';
import { usuariosQueryEsquema, crearUsuarioInternoEsquema } from '../esquemas/usuario.esquema';
import {
    listarUsuariosControlador, listarRolesControlador,
    crearUsuarioInternoControlador, cambiarEstadoUsuarioControlador
} from '../controlador/usuarios.controlador';

const rutasUsuarios = Router();
rutasUsuarios.use(autenticar, autorizarRoles('Administrador'));

rutasUsuarios.get('/roles', listarRolesControlador);
rutasUsuarios.get('/', validar({ query: usuariosQueryEsquema }), listarUsuariosControlador);
rutasUsuarios.post('/', validar({ body: crearUsuarioInternoEsquema }), crearUsuarioInternoControlador);
rutasUsuarios.patch('/:id/estado', validar({ params: idParametroEsquema, body: cambiarEstadoEsquema }), cambiarEstadoUsuarioControlador);

export default rutasUsuarios;