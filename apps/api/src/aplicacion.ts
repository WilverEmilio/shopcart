import express from 'express';
import cors from 'cors'; 
import helmet from 'helmet';
import {env} from './config/env';
import rutasAutenticacion from './modulos/autenticacion/rutas/autenticacion.rutas';
import rutasCatalogo from './modulos/productos/rutas/catalogo.rutas';
import { manejoErroresMiddleware } from './shared/middleware/manejo-errores.middleware';
import { ErrorAplicacion } from './shared/errores/error-aplicacion';
import rutasCarrito from './modulos/carrito/rutas/carrito.rutas';
import rutasDirecciones from './modulos/direcciones/rutas/direcciones.rutas';
import rutasCheckout from './modulos/checkout/rutas/checkout.rutas';
import rutasPedidos from './modulos/pedidos/rutas/pedidos.rutas';
import './config/zod'

const aplicacion = express();

aplicacion.use(helmet());
aplicacion.use(cors({
    origin: env.database.corsOrigen, credentials: true
}));
aplicacion.use(express.json({limit: '100kb'}));

aplicacion.get('/api/estado', (_s, r)=> {
    r.status(200).json({
        mensaje: 'API funcionando correctamente'
    })
});
aplicacion.use('/api/autenticacion', rutasAutenticacion);
aplicacion.use('/api/catalogo', rutasCatalogo);
aplicacion.use('/api/carrito', rutasCarrito);
aplicacion.use('/api/direcciones',rutasDirecciones);
aplicacion.use('/api/checkout', rutasCheckout);
aplicacion.use('/api/pedidos', rutasPedidos);

aplicacion.use((_s, _r, siguiente) => {
    siguiente(new ErrorAplicacion(
        'Recurso no encontrado',
        40400,
        404
    ));
});
aplicacion.use(manejoErroresMiddleware);

export default aplicacion;