const formatoMoneda = new Intl.NumberFormat('es-GT',{
    style: 'currency',
    currency: 'GTQ'
});
const formatoFecha = new Intl.DateTimeFormat('es-GT',{
    dateStyle: 'medium'
});

export const formatearMoneda = (valor: number): string => formatoMoneda.format(valor);
export const formatearFecha = (iso: string): string => formatoFecha.format(new Date(iso));

export const redondear = (valor: number): number => Math.round((valor + Number.EPSILON)* 100) / 100;

export const formatearTemporizador = (milisegundos: number): string => {
    const total = Math.ceil(milisegundos / 1000);
    const minutos = Math.floor(total / 60);
    const segundos = total % 60;
    return`${String(minutos).padStart(2, '0')}:${String(segundos).padStart(2, '0')}`
}