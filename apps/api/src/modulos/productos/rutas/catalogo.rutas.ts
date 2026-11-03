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
import { crearProductoControlador } from '../controladores/crear-producto.controlador';
import { actualizarProductoControlador } from '../controladores/actualizar-producto.controlador';
import { cambiarEstadoProductoControlador } from '../controladores/cambiar-estado-producto.controlador';
import { eliminarProductoControlador } from '../controladores/eliminar-producto.controlador';

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
rutasCatalogo.post('/productos', autenticar, autorizarRoles('Administrador'), crearProductoControlador);
rutasCatalogo.put('/productos/:id', autenticar,autorizarRoles('Administrador'),actualizarProductoControlador);
rutasCatalogo.patch('/productos/:id/estado', autenticar,autorizarRoles('Administrador'), cambiarEstadoProductoControlador);
rutasCatalogo.delete('/productos/:id',autenticar,autorizarRoles('Administrador'),eliminarProductoControlador)

export default rutasCatalogo;