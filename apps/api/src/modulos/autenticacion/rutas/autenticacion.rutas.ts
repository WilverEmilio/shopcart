import {Router} from 'express';

import {
    registrarClienteControlador, 
    iniciarSesionControlador
} from '../controladores/autentiaion.controlador';

const rutasAutenticacion = Router();

rutasAutenticacion.post('/registro', registrarClienteControlador);
rutasAutenticacion.post('/iniciar-sesion', iniciarSesionControlador);

export default rutasAutenticacion;