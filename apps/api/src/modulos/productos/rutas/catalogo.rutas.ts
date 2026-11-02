import { Router } from 'express';
import {
  listarProductosControlador
} from '../controladores/catalogo.controlador';

const rutasCatalogo = Router();

rutasCatalogo.get('/productos', listarProductosControlador);

export default rutasCatalogo;