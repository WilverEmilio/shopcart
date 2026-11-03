import clienteHttp from "../../../servicios/clienteHttp";

export const obtenerProductos = async () => {
    const respuesta = await clienteHttp.get('/productos');
    return respuesta.data;
};