import { Router } from 'express';
import {listarProductosControlador} from '../controladores/catalogo.controlador';
import { obtenerDetalleProductoControlador } from '../controladores/producto-detalle.controlador';
import { listarCategoriasControlador } from '../controladores/categorias.controlador';
import { autenticar } from '../../../shared/middleware/autenticacion.middleware';
import { autorizarRoles } from '../../../shared/middleware/autorizacion.middleware';
import { obtenerCategoriaDetalleControlador } from '../controladores/categoria-detalle.controlador';
import { crearCategoriaControlador } from '../controladores/categoria-crear.controlador';
import { actualizarCategoriaControlador } from '../controladores/categorias.controlador';
import { cambiarEstadoCategoriaControlador } from '../controladores/categorias.controlador';
import { eliminarCategoriaControlador } from '../controladores/eliminar-categoria.controlador';
import { listarAtributosControlador } from '../controladores/listar-atributos.controlador';

const rutasCatalogo = Router();

rutasCatalogo.get('/productos', listarProductosControlador);
rutasCatalogo.get('/productos/:id', obtenerDetalleProductoControlador);
rutasCatalogo.get('/categorias', autenticar,autorizarRoles('Administrador'), listarCategoriasControlador);
rutasCatalogo.get('/categorias/:id', autenticar,autorizarRoles('Administrador'), obtenerCategoriaDetalleControlador);
rutasCatalogo.post('/categorias', autenticar, autorizarRoles('Administrador'), crearCategoriaControlador);
rutasCatalogo.put('/categorias/:id', autenticar, autorizarRoles('Administrador'), actualizarCategoriaControlador)
rutasCatalogo.patch('/categorias/:id/estado', autenticar,autorizarRoles('Administrador'),cambiarEstadoCategoriaControlador);
rutasCatalogo.delete('/categorias/:id', autenticar,autorizarRoles('Administrador'), eliminarCategoriaControlador);
rutasCatalogo.get('/atributos', listarAtributosControlador); 

export default rutasCatalogo;