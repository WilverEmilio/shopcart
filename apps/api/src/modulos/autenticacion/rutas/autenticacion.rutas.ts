import {Router} from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import {
    registrarClienteControlador, 
    iniciarSesionControlador
} from '../controladores/autentiaion.controlador';

const rutasAutenticacion = Router();

rutasAutenticacion.post('/registro', registrarClienteControlador);
rutasAutenticacion.post('/iniciar-sesion', iniciarSesionControlador);

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

export default rutasAutenticacion;