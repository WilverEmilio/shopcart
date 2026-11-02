import { Router } from 'express';
import {listarProductosControlador} from '../controladores/catalogo.controlador';
import { obtenerDetalleProductoControlador } from '../controladores/producto-detalle.controlador';

const rutasCatalogo = Router();

rutasCatalogo.get('/productos', listarProductosControlador);
rutasCatalogo.get('/productos/:id', obtenerDetalleProductoControlador)

export default rutasCatalogo;