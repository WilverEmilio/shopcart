import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from 'recharts';
import { formatearMoneda } from '../../../utilidades/formato';
import { PALETA_CATEGORIAS } from '../paleta';
import type { FilaVentasCategoria } from '../tipos/reportes';


export function GraficaVentasCategoria({ datos }: { datos: FilaVentasCategoria[] }) {
  return (
    <div className="grid items-center gap-4 sm:grid-cols-2">
      <div role="img" aria-label="Gráfica circular de ventas netas por categoría">
        <ResponsiveContainer width="100%" height={240}>
          <PieChart>
            <Pie data={datos} dataKey="ventasNetas" nameKey="categoria" innerRadius={55} outerRadius={95} paddingAngle={2}>
              {datos.map((d, i) => (
                <Cell key={d.idCategoria} fill={PALETA_CATEGORIAS[i % PALETA_CATEGORIAS.length]} />
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
              <span className="h-3 w-3 shrink-0 rounded-sm" style={{ backgroundColor: PALETA_CATEGORIAS[i % PALETA_CATEGORIAS.length] }} />
              {d.categoria}
            </span>
            <span className="text-right text-slate-600">
              {formatearMoneda(d.ventasNetas)} · {d.porcentaje} %
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}