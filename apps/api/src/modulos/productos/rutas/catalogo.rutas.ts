import { Router } from 'express';
import {listarProductosControlador} from '../controladores/catalogo.controlador';
import { obtenerDetalleProductoControlador } from '../controladores/producto-detalle.controlador';
import { listarCategoriasControlador } from '../controladores/categorias.controlador';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { obtenerCategoriaDetalleControlador } from '../controladores/categoria-detalle.controlador';

const rutasCatalogo = Router();

rutasCatalogo.get('/productos', listarProductosControlador);
rutasCatalogo.get('/productos/:id', obtenerDetalleProductoControlador);
rutasCatalogo.get('/categorias', autenticar,autorizarRoles('Administrador'), listarCategoriasControlador);
rutasCatalogo.get('/categorias/:id', autenticar,autorizarRoles('Administrador'), obtenerCategoriaDetalleControlador)

export default rutasCatalogo;