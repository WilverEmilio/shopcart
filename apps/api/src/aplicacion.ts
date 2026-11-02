import express from 'express';
import rutasAutenticacion from './modulos/autenticacion/rutas/autenticacion.rutas';
import { manejoErroresMiddleware } from './shared/middleware/manejo-errores.middleware';

const aplicacion = express();

aplicacion.use(express.json());

aplicacion.use(
    '/api/autenticacion',
    rutasAutenticacion
);

aplicacion.get('/api/estado', (_solicitud, respuesta) =>{
    respuesta.status(200).json({
        mensaje: 'API funcionando correctamente'
    })
}); 

aplicacion.use(manejoErroresMiddleware);
export default aplicacion;