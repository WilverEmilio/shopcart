import {Router} from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';

import {
    registrarClienteControlador, 
    iniciarSesionControlador,
    renovarTokenControlador,
    cerrarSesionControlador,
    obtenerPerfilControlador
} from '../controladores/autentiaion.controlador';
import { inicioSesionEsquema, registroClienteEsquema, tokenRefrescoEsquema } from '../esquemas/autenticacion.esquema';
import { validar } from '../../../shared/middleware/validar.middleware';

const rutasAutenticacion = Router();

rutasAutenticacion.post('/registro', validar({body:registroClienteEsquema}), registrarClienteControlador );
rutasAutenticacion.post('/iniciar-sesion',validar({ body: inicioSesionEsquema }), iniciarSesionControlador);
rutasAutenticacion.post('/renovar-token',validar({body:tokenRefrescoEsquema}), renovarTokenControlador);
rutasAutenticacion.post('/cerrar-sesion', validar({body: tokenRefrescoEsquema}), cerrarSesionControlador);
rutasAutenticacion.get('/perfil', autenticar, obtenerPerfilControlador);

export default rutasAutenticacion;