const formatoMoneda = new Intl.NumberFormat('es-GT',{
    style: 'currency',
    currency: 'GTQ'
});
const formatoFecha = new Intl.DateTimeFormat('es-GT',{
    dateStyle: 'medium'
});

export const formatearMoneda = (valor: number): string => formatoMoneda.format(valor);
export const formatearFecha = (iso: string): string => formatoFecha.format(new Date(iso));