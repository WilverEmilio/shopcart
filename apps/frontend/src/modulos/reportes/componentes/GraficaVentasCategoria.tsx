import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from 'recharts';
import { formatearMoneda } from '../../../utilidades/formato';
import type { FilaVentasCategoria } from '../tipos/reportes';

const COLORES = ['#4f46e5', '#0ea5e9', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#64748b'];

export function GraficaVentasCategoria({ datos }: { datos: FilaVentasCategoria[] }) {
  return (
    <div className="grid items-center gap-4 sm:grid-cols-2">
      <div role="img" aria-label="Gráfica circular de ventas netas por categoría">
        <ResponsiveContainer width="100%" height={240}>
          <PieChart>
            <Pie data={datos} dataKey="ventasNetas" nameKey="categoria" innerRadius={55} outerRadius={95} paddingAngle={2}>
              {datos.map((d, i) => (
                <Cell key={d.idCategoria} fill={COLORES[i % COLORES.length]} />
              ))}
            </Pie>
            <Tooltip formatter={(valor) => formatearMoneda(Number(valor))} />
          </PieChart>
        </ResponsiveContainer>
      </div>

      <ul className="space-y-2 text-sm">
        {datos.map((d, i) => (
          <li key={d.idCategoria} className="flex items-center justify-between gap-2">
            <span className="flex items-center gap-2">
              <span className="h-3 w-3 shrink-0 rounded-sm" style={{ backgroundColor: COLORES[i % COLORES.length] }} />
              {d.categoria}
            </span>
            <span className="text-right text-gray-600">
              {formatearMoneda(d.ventasNetas)} · {d.porcentaje} %
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}