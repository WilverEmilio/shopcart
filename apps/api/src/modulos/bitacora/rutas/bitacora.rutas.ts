import { Router } from 'express';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { validar } from '../../../shared/middleware/validar.middleware';
import { bitacoraQueryEsquema } from '../esquemas/bitacora.esquema';
import { listarBitacoraControlador } from '../controladores/bitacora.controlador';

const rutasBitacora = Router();

rutasBitacora.get('/', autenticar, autorizarRoles('Administrador'), validar({ query: bitacoraQueryEsquema }), listarBitacoraControlador);

export default rutasBitacora;