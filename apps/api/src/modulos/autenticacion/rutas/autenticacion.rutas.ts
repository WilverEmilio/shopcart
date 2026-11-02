import {Router} from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';

import {
    registrarClienteControlador, 
    iniciarSesionControlador,
    renovarTokenControlador
} from '../controladores/autentiaion.controlador';

const rutasAutenticacion = Router();

rutasAutenticacion.post('/registro', registrarClienteControlador);
rutasAutenticacion.post('/iniciar-sesion', iniciarSesionControlador);
rutasAutenticacion.post('/renovar-token', renovarTokenControlador)

rutasAutenticacion.get(
    '/perfil',
    autenticar,
    (solicitud, respuesta) => {
        respuesta.status(200).json({
            mensaje: 'Usuario autenticado correctamente',
            datos: solicitud.usuarioAutenticado
        });
    }
);

rutasAutenticacion.get(
    '/solo-administrador',
    autenticar,
    autorizarRoles('Administrador'),
    (_solicitud, respuesta)  => {
        respuesta.status(200).json({
            mensaje: 'Acceso permitodo para Administradores'
        });
    }
); 

rutasAutenticacion.get(
    '/operaciones',
    autenticar,
    autorizarRoles('Operador', 'Administrador'),
    (_solicitud, respuesta)  =>{
        respuesta.status(200).json({
            mensaje: 'Acceso permitod para Operadores y Administradores'
        });
    }
);

export default rutasAutenticacion;