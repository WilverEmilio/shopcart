import { BloqueConsulta } from '../../../componentes/BloqueConsulta';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { formatearFechaCorta, formatearMoneda } from '../../../utilidades/formato';
import { FiltroRango } from '../componentes/FiltroRango';
import { GraficaTopProductos } from '../componentes/GraficaTopProductos';
import { GraficaVentasCategoria } from '../componentes/GraficaVentasCategoria';
import { GraficaVentasPeriodo } from '../componentes/GraficaVentasPeriodo';
import {  TablaCarritosAbandonados } from '../componentes/TablaCarritosAbandonados';
import { OPCIONES_ORDEN_ABANDONADOS } from '../constante';
import { TarjetaKpi } from '../componentes/TarjetaKpi';
import { useResumen, useTopProductos, useVentasCategoria, useVentasPeriodo } from '../hooks/useReportes';
import { rangoUltimosDias } from '../rangos';
import type { Agrupacion, FiltrosAbandonados, OrdenTop, RangoFechas } from '../tipos/reportes';
import type { ReactNode } from 'react';
const AGRUPACIONES: { valor: Agrupacion; etiqueta: string }[] = [
  { valor: 'DIA', etiqueta: 'Día' },
  { valor: 'SEMANA', etiqueta: 'Semana' },
  { valor: 'MES', etiqueta: 'Mes' },
];

const ORDENES_TOP: { valor: OrdenTop; etiqueta: string }[] = [
  { valor: 'UNIDADES', etiqueta: 'Por unidades' },
  { valor: 'VENTAS', etiqueta: 'Por monto' },
];

const variacion = (actual: number, anterior: number): number | null =>
  anterior === 0 ? null : ((actual - anterior) / anterior) * 100;

interface PropiedadesSelector<T extends string> {
  opciones: { valor: T; etiqueta: string }[];
  valor: T;
  alCambiar: (valor: T) => void;
  etiqueta: string;
}

function SelectorSegmentado<T extends string>({ opciones, valor, alCambiar, etiqueta }: PropiedadesSelector<T>) {
  return (
    <div role="group" aria-label={etiqueta} className="inline-flex overflow-hidden rounded-md border border-gray-300">
      {opciones.map((o) => (
        <button
          key={o.valor}
          type="button"
          aria-pressed={o.valor === valor}
          onClick={() => alCambiar(o.valor)}
          className={`px-3 py-1.5 text-sm ${o.valor === valor ? 'bg-indigo-600 text-white' : 'bg-white hover:bg-gray-100'}`}
        >
          {o.etiqueta}
        </button>
      ))}
    </div>
  );
}

function Tarjeta({ titulo, acciones, children }: { titulo: string; acciones?: ReactNode; children: ReactNode }) {
  return (
    <section className="space-y-4 rounded-lg border border-gray-200 bg-white p-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-lg font-semibold">{titulo}</h2>
        {acciones}
      </div>
      {children}
    </section>
  );
}

export function PaginaDashboard() {
  const { params, actualizar } = useParametrosUrl();

  const porDefecto = rangoUltimosDias(30);
  const rango: RangoFechas = {
    fechaDesde: params.get('desde') ?? porDefecto.fechaDesde,
    fechaHasta: params.get('hasta') ?? porDefecto.fechaHasta,
  };
  const agrupacion = AGRUPACIONES.find((a) => a.valor === params.get('agrup'))?.valor ?? 'DIA';
  const ordenTop = ORDENES_TOP.find((o) => o.valor === params.get('top'))?.valor ?? 'UNIDADES';

  const ordenAbandonados = OPCIONES_ORDEN_ABANDONADOS.find((o) => o.valor === params.get('abOrden'))?.valor ?? 'HorasInactivo|DESC';
  const [abOrdenarPor, abDireccion] = ordenAbandonados.split('|') as [FiltrosAbandonados['ordenarPor'], FiltrosAbandonados['direccion']];
  const abPagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const resumen = useResumen(rango);
  const ventasPeriodo = useVentasPeriodo(rango, agrupacion);
  const ventasCategoria = useVentasCategoria(rango);
  const topProductos = useTopProductos(rango, ordenTop);

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-semibold">Dashboard</h1>
        <p className="text-sm text-gray-500">
          Del {formatearFechaCorta(rango.fechaDesde)} al {formatearFechaCorta(rango.fechaHasta)}. Las ventas netas descuentan las devoluciones.
        </p>
      </div>

      <FiltroRango key={`${rango.fechaDesde}|${rango.fechaHasta}`} rango={rango} alCambiar={actualizar} />

      <BloqueConsulta consulta={resumen}>
        {(r) => (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <TarjetaKpi
              titulo="Ventas netas"
              valor={formatearMoneda(r.ventasNetas)}
              variacion={variacion(r.ventasNetas, r.ventasNetasAnterior)}
              detalle={`Ventas brutas ${formatearMoneda(r.ventasBrutas)}`}
            />
            <TarjetaKpi titulo="Pedidos" valor={String(r.pedidos)} variacion={variacion(r.pedidos, r.pedidosAnterior)} />
            <TarjetaKpi titulo="Ticket promedio" valor={formatearMoneda(r.ticketPromedio)} />
            <TarjetaKpi titulo="Unidades vendidas" valor={String(r.unidadesNetas)} detalle="Netas de devoluciones" />
            <TarjetaKpi titulo="Devoluciones" valor={formatearMoneda(r.devoluciones)} />
            <TarjetaKpi
              titulo="Cancelaciones"
              valor={String(r.pedidosCancelados)}
              detalle={`Monto cancelado ${formatearMoneda(r.montoCancelado)}`}
            />
            <TarjetaKpi
              titulo="Carritos abandonados"
              valor={String(r.carritosAbandonados)}
              detalle={`Valor ${formatearMoneda(r.valorCarritosAbandonados)} (a hoy)`}
            />
          </div>
        )}
      </BloqueConsulta>

      <Tarjeta
        titulo="Ventas por periodo"
        acciones={
          <SelectorSegmentado
            etiqueta="Agrupar ventas por"
            opciones={AGRUPACIONES}
            valor={agrupacion}
            alCambiar={(a) => actualizar({ agrup: a === 'DIA' ? undefined : a })}
          />
        }
      >
        <BloqueConsulta consulta={ventasPeriodo} estaVacio={(d) => d.every((f) => f.pedidos === 0)}>
          {(datos) => <GraficaVentasPeriodo datos={datos} />}
        </BloqueConsulta>
      </Tarjeta>

      <div className="grid gap-6 lg:grid-cols-2">
        <Tarjeta titulo="Ventas por categoría">
          <BloqueConsulta consulta={ventasCategoria} estaVacio={(d) => d.length === 0}>
            {(datos) => <GraficaVentasCategoria datos={datos} />}
          </BloqueConsulta>
        </Tarjeta>

        <Tarjeta
          titulo="Top 10 productos"
          acciones={
            <SelectorSegmentado
              etiqueta="Ordenar productos"
              opciones={ORDENES_TOP}
              valor={ordenTop}
              alCambiar={(o) => actualizar({ top: o === 'UNIDADES' ? undefined : o })}
            />
          }
        >
          <BloqueConsulta consulta={topProductos} estaVacio={(d) => d.length === 0}>
            {(datos) => <GraficaTopProductos datos={datos} ordenarPor={ordenTop} />}
          </BloqueConsulta>
        </Tarjeta>
      </div>

      <Tarjeta titulo="Carritos abandonados">
        <TablaCarritosAbandonados
          filtros={{ ordenarPor: abOrdenarPor, direccion: abDireccion, pagina: abPagina, registrosPorPagina: 10 }}
          orden={ordenAbandonados}
          alCambiarOrden={(valor) => actualizar({ abOrden: valor })}
          alCambiarPagina={(p) => actualizar({ pagina: String(p) })}
        />
      </Tarjeta>
    </main>
  );
}