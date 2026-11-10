import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { etiquetaCorta, formatearCompacto, formatearMoneda } from '../../../utilidades/formato';
import { COLOR_MARCA, COLOR_MARCA_SUAVE } from '../paleta';
import type { FilaVentasPeriodo } from '../tipos/reportes';

function TooltipPeriodo({ active, payload }: { active?: boolean; payload?: { payload: FilaVentasPeriodo }[] }) {
  if (!active || !payload?.length) return null;
  const fila = payload[0].payload;

  return (
    <div className="rounded-control border border-slate-200 bg-white p-3 text-xs shadow-elevada">
      <p className="mb-1 font-semibold">{fila.etiqueta}</p>
      <p>Ventas netas: {formatearMoneda(fila.ventasNetas)}</p>
      <p>Pedidos: {fila.pedidos}</p>
      <p>Ticket promedio: {formatearMoneda(fila.ticketPromedio)}</p>
      {fila.devoluciones > 0 && <p className="text-red-600">Devoluciones: {formatearMoneda(fila.devoluciones)}</p>}
    </div>
  );
}

export function GraficaVentasPeriodo({ datos }: { datos: FilaVentasPeriodo[] }) {
  const total = datos.reduce((suma, f) => suma + f.ventasNetas, 0);

  return (
    <div role="img" aria-label={`Gráfica de ventas netas por periodo. Total del rango: ${formatearMoneda(total)}.`}>
      <ResponsiveContainer width="100%" height={288}>
        <AreaChart data={datos.map((f) => ({ ...f, eje: etiquetaCorta(f.etiqueta) }))} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} />
          <XAxis dataKey="eje" tick={{ fontSize: 12 }} interval="preserveStartEnd" minTickGap={24} />
          <YAxis tickFormatter={(v: number) => formatearCompacto(v)} tick={{ fontSize: 12 }} width={52} />
          <Tooltip content={<TooltipPeriodo />} />
          <Area type="monotone" dataKey="ventasNetas" name="Ventas netas" stroke={COLOR_MARCA} strokeWidth={2} fill={COLOR_MARCA_SUAVE} />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}