import axios from 'axios';
import entorno from '../configuracion/entorno';
import { useSesionEstado } from '../estados/sesionEstado';

const clienteHttp = axios.create({
    baseURL: entorno.apiUrl,
    timeout: 15000,
    withCredentials: true,
    headers: {
        "Content-Type": 'application/json',
        Accept: 'application/json',
    },
}); 

clienteHttp.interceptors.request.use((config) =>{
    const token = useSesionEstado.getState().tokenAcceso;

    if (token) {
        config.headers.Authorization =  `Bearer ${token}`;
    }
    return config;
})

export default clienteHttp;