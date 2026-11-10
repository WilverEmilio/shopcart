import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { formatearCompacto, formatearMoneda } from '../../../utilidades/formato';
import { COLOR_MARCA } from '../paleta';
import type { FilaTopProducto, OrdenTop } from '../tipos/reportes';

interface Propiedades {
  datos: FilaTopProducto[];
  ordenarPor: OrdenTop;
}

export function GraficaTopProductos({ datos, ordenarPor }: Propiedades) {
  const porVentas = ordenarPor === 'VENTAS';
  const clave = porVentas ? 'ventasNetas' : 'unidades';

  return (
    <div role="img" aria-label={`Gráfica de los ${datos.length} productos más vendidos por ${porVentas ? 'monto' : 'unidades'}`}>
      <ResponsiveContainer width="100%" height={Math.max(240, datos.length * 38 + 40)}>
        <BarChart data={datos} layout="vertical" margin={{ top: 4, right: 16, left: 8, bottom: 4 }}>
          <CartesianGrid strokeDasharray="3 3" horizontal={false} />
          <XAxis type="number" tick={{ fontSize: 12 }} tickFormatter={(v: number) => formatearCompacto(v)} />
          <YAxis
            type="category"
            dataKey="producto"
            width={150}
            tick={{ fontSize: 12 }}
            tickFormatter={(v: string) => (v.length > 24 ? `${v.slice(0, 23)}…` : v)}
          />
          <Tooltip formatter={(valor) => (porVentas ? formatearMoneda(Number(valor)) : `${valor} unidades`)} />
          <Bar dataKey={clave} name={porVentas ? 'Ventas netas' : 'Unidades'} fill={COLOR_MARCA} radius={[0, 4, 4, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}