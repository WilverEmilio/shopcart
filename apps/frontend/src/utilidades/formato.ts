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

const formatoFechaHora = new Intl.DateTimeFormat('es-GT', {
    dateStyle: 'medium', 
    timeStyle: 'short'
});

export const formatearFechaHora = (iso: string): string => formatoFechaHora.format(new Date(iso));

const formatoCompacto = new Intl.NumberFormat('es-GT', { notation: 'compact', maximumFractionDigits: 1 });
export const formatearCompacto = (valor: number): string => formatoCompacto.format(valor);

export const formatearFechaCorta = (iso: string): string => {
  const [anio, mes, dia] = iso.slice(0, 10).split('-');
  return `${dia}/${mes}/${anio}`;
};

export const etiquetaCorta = (etiqueta: string): string => {
  const esSemana = etiqueta.startsWith('Sem ');
  const base = esSemana ? etiqueta.slice(4) : etiqueta;
  const partes = base.split('-');

  let texto = base;
  if (partes.length === 3) texto = `${partes[2]}/${partes[1]}`;
  else if (partes.length === 2) texto = `${partes[1]}/${partes[0]}`;

  return esSemana ? `Sem ${texto}` : texto;
};