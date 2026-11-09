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
import { actualizarVarianteEsquema, cambiarEstadoEsquema, cambiarPrecioEsquema, crearVarianteEsquema, reemplazarImagenesEsquema, actualizarProductoEsquema, categoriaEsquema,categoriasQueryEsquema,crearProductoEsquema } from '../esquemas/producto.esquema';
import { actualizarVarianteControlador, cambiarEstadoVarianteControlador, cambiarPrecioVarianteControlador, crearVarianteControlador, eliminarVarianteControlador, reemplazarImagenesControlador } from '../controladores/variante.controlador';


const admin = [autenticar, autorizarRoles('Administrador')];
const rutasCatalogo = Router();

rutasCatalogo.get('/categorias', ...admin, validar({ query: categoriasQueryEsquema }), listarCategoriasControlador);
rutasCatalogo.get('/categorias/:id', ...admin, validar({ params: idParametroEsquema }), obtenerCategoriaDetalleControlador);
rutasCatalogo.post('/categorias', ...admin, validar({ body: categoriaEsquema }), crearCategoriaControlador);
rutasCatalogo.put('/categorias/:id', ...admin, validar({ params: idParametroEsquema, body: categoriaEsquema }), actualizarCategoriaControlador);
rutasCatalogo.patch('/categorias/:id/estado', ...admin, validar({ params: idParametroEsquema, body: cambiarEstadoEsquema }), cambiarEstadoCategoriaControlador);
rutasCatalogo.delete('/categorias/:id', ...admin, validar({ params: idParametroEsquema }), eliminarCategoriaControlador);
rutasCatalogo.get('/categorias-activas', listarCategoriasPublicasControlador);


rutasCatalogo.get('/atributos', listarAtributosControlador); 

rutasCatalogo.get('/productos', autenticarOpcional,validar({query:catalogoQueryEsquema}),listarProductosControlador);
rutasCatalogo.get('/productos/:id', autenticarOpcional,validar({params:idParametroEsquema}), obtenerDetalleProductoControlador);
rutasCatalogo.post('/productos', ...admin, validar({ body: crearProductoEsquema }), crearProductoControlador);
rutasCatalogo.put('/productos/:id', ...admin, validar({ params: idParametroEsquema, body: actualizarProductoEsquema }), actualizarProductoControlador);
rutasCatalogo.patch('/productos/:id/estado', ...admin, validar({ params: idParametroEsquema, body: cambiarEstadoEsquema }), cambiarEstadoProductoControlador);
rutasCatalogo.delete('/productos/:id', ...admin, validar({ params: idParametroEsquema }), eliminarProductoControlador); 

rutasCatalogo.post('/productos/:id/variantes', ...admin, validar({ params: idParametroEsquema, body: crearVarianteEsquema }), crearVarianteControlador);
rutasCatalogo.put('/productos/:id/imagenes', ...admin, validar({ params: idParametroEsquema, body: reemplazarImagenesEsquema }), reemplazarImagenesControlador);
rutasCatalogo.put('/variantes/:id', ...admin, validar({ params: idParametroEsquema, body: actualizarVarianteEsquema }), actualizarVarianteControlador);
rutasCatalogo.patch('/variantes/:id/estado', ...admin, validar({ params: idParametroEsquema, body: cambiarEstadoEsquema }), cambiarEstadoVarianteControlador);
rutasCatalogo.patch('/variantes/:id/precio', ...admin, validar({ params: idParametroEsquema, body: cambiarPrecioEsquema }), cambiarPrecioVarianteControlador);
rutasCatalogo.delete('/variantes/:id', ...admin, validar({ params: idParametroEsquema }), eliminarVarianteControlador);

export default rutasCatalogo;