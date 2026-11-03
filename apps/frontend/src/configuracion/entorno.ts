const entorno = {
    apiUrl: import.meta.env.VITE_API_URL,
    nombreAplicacion: import.meta.env.VITE_APP_NAME || 'ShopCart',
};

if(!entorno.apiUrl){
    throw new Error(
        'No se ha confiurado la URL de la API.'
    );
}

export default entorno;