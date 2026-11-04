import { Router } from 'express';
import {listarProductosControlador} from '../controladores/catalogo.controlador';
import { obtenerDetalleProductoControlador } from '../controladores/producto-detalle.controlador';
import { listarCategoriasControlador, listarCategoriasPublicasControlador } from '../controladores/categorias.controlador';
import { autenticar, autenticarOpcional } from '../../../shared/middleware/autenticacion.middleware';
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
import { validar } from '../../../shared/middleware/validar.middleware';
import { catalogoQueryEsquema } from '../esquemas/catalogo.esquema';
import { idParametroEsquema } from '../../../shared/esquemas/comunes.esquema';

const rutasCatalogo = Router();

rutasCatalogo.get('/categorias', autenticar,autorizarRoles('Administrador'),validar({query:catalogoQueryEsquema}), listarCategoriasControlador);
rutasCatalogo.get('/categorias/:id', autenticar,autorizarRoles('Administrador'),validar({params:idParametroEsquema}), obtenerCategoriaDetalleControlador);
rutasCatalogo.post('/categorias', autenticar, autorizarRoles('Administrador'), validar({query:catalogoQueryEsquema}),crearCategoriaControlador);
rutasCatalogo.put('/categorias/:id', autenticar, autorizarRoles('Administrador'),validar({params:idParametroEsquema}), actualizarCategoriaControlador)
rutasCatalogo.patch('/categorias/:id/estado', autenticar,autorizarRoles('Administrador'),validar({params:idParametroEsquema}),cambiarEstadoCategoriaControlador);
rutasCatalogo.delete('/categorias/:id', autenticar,autorizarRoles('Administrador'), validar({params:idParametroEsquema}),eliminarCategoriaControlador);
rutasCatalogo.get('/categorias-activas', listarCategoriasPublicasControlador);


rutasCatalogo.get('/atributos', listarAtributosControlador); 

rutasCatalogo.get('/productos', autenticarOpcional,validar({query:catalogoQueryEsquema}),listarProductosControlador);
rutasCatalogo.get('/productos/:id', autenticarOpcional,validar({params:idParametroEsquema}), obtenerDetalleProductoControlador);
rutasCatalogo.post('/productos', autenticar, autorizarRoles('Administrador'), validar({query:catalogoQueryEsquema}),crearProductoControlador);
rutasCatalogo.put('/productos/:id', autenticar,autorizarRoles('Administrador'),validar({params:idParametroEsquema}), actualizarProductoControlador);
rutasCatalogo.patch('/productos/:id/estado', autenticar,autorizarRoles('Administrador'),validar({params:idParametroEsquema}),  cambiarEstadoProductoControlador);
rutasCatalogo.delete('/productos/:id',autenticar,autorizarRoles('Administrador'),validar({params:idParametroEsquema}), eliminarProductoControlador)

export default rutasCatalogo;