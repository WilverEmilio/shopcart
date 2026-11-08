import { formatearFechaHora, formatearMoneda } from '../../../utilidades/formato';
import type { DetallePedido } from '../tipos/pedido';
import { InsigniaEstado } from './InsigniaEstado';

interface Propiedades {
  detalle: DetallePedido;
  mostrarCliente?: boolean;
}

export function DetallePedidoVista({ detalle, mostrarCliente = false }: Propiedades) {
  const reembolsado = detalle.devoluciones.reduce((suma, d) => suma + d.montoReembolso, 0);
  const hayDevueltos = detalle.items.some((i) => i.cantidadDevuelta > 0);

  return (
    <div className="space-y-8">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Pedido {detalle.numeroPedido}</h1>
          <p className="text-sm text-gray-500">Realizado el {formatearFechaHora(detalle.fechaCreacion)}</p>
          {mostrarCliente && (
            <p className="text-sm text-gray-600">
              Cliente: {detalle.nombreCliente} ({detalle.correoCliente})
            </p>
          )}
        </div>
        <InsigniaEstado estado={detalle.estado} />
      </header>

      <div className="grid gap-8 lg:grid-cols-[1fr_20rem]">
        <section aria-labelledby="titulo-productos">
          <h2 id="titulo-productos" className="mb-3 text-lg font-semibold">
            Productos
          </h2>
          <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">Producto</th>
                  <th className="px-4 py-3 text-right">Precio</th>
                  <th className="px-4 py-3 text-right">Cant.</th>
                  {hayDevueltos && <th className="px-4 py-3 text-right">Devueltas</th>}
                  <th className="px-4 py-3 text-right">Subtotal</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {detalle.items.map((i) => (
                  <tr key={i.idDetallePedido}>
                    <td className="px-4 py-3">
                      <p className="font-medium">{i.nombreProducto}</p>
                      {i.atributos && <p className="text-gray-500">{i.atributos}</p>}
                      <p className="text-xs text-gray-400">SKU {i.sku}</p>
                    </td>
                    <td className="px-4 py-3 text-right">{formatearMoneda(i.precioUnitario)}</td>
                    <td className="px-4 py-3 text-right">{i.cantidad}</td>
                    {hayDevueltos && <td className="px-4 py-3 text-right">{i.cantidadDevuelta}</td>}
                    <td className="px-4 py-3 text-right">{formatearMoneda(i.subottal)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <aside className="space-y-2 rounded-lg border border-gray-200 bg-white p-5 text-sm lg:self-start">
          <h2 className="mb-2 text-lg font-semibold">Totales</h2>
          <div className="flex justify-between">
            <span className="text-gray-600">Subtotal</span>
            <span>{formatearMoneda(detalle.subtotal)}</span>
          </div>
          {detalle.descuento > 0 && (
            <div className="flex justify-between text-green-700">
              <span>Descuento{detalle.codigoCupon ? ` (${detalle.codigoCupon})` : ''}</span>
              <span>−{formatearMoneda(detalle.descuento)}</span>
            </div>
          )}
          <div className="flex justify-between">
            <span className="text-gray-600">Envío{detalle.nombreEnvio ? ` (${detalle.nombreEnvio})` : ''}</span>
            <span>{detalle.costoEnvio === 0 ? 'Gratis' : formatearMoneda(detalle.costoEnvio)}</span>
          </div>
          <div className="flex justify-between border-t border-gray-200 pt-2 text-base font-semibold">
            <span>Total</span>
            <span>{formatearMoneda(detalle.total)}</span>
          </div>
          <p className="text-xs text-gray-500">Incluye IVA de {formatearMoneda(detalle.iva)}.</p>
          {reembolsado > 0 && (
            <div className="flex justify-between border-t border-gray-200 pt-2 text-red-700">
              <span>Reembolsado</span>
              <span>−{formatearMoneda(reembolsado)}</span>
            </div>
          )}
        </aside>
      </div>

      <section aria-labelledby="titulo-entrega">
        <h2 id="titulo-entrega" className="mb-3 text-lg font-semibold">
          Entrega
        </h2>
        <div className="rounded-lg border border-gray-200 bg-white p-4 text-sm text-gray-700">
          <p className="font-medium">{detalle.destinatarioEnvio}</p>
          <p>
            {detalle.direccionEnvio}, {detalle.municipioEnvio}, {detalle.departamentoEnvio}
          </p>
          {detalle.referenciaEnvio && <p className="text-gray-500">Ref.: {detalle.referenciaEnvio}</p>}
          <p className="text-gray-500">Tel. {detalle.telefonoEnvio}</p>
        </div>
      </section>

      <section aria-labelledby="titulo-historial">
        <h2 id="titulo-historial" className="mb-3 text-lg font-semibold">
          Historial de estados
        </h2>
        <ol className="space-y-3 border-l-2 border-gray-200 pl-5">
          {detalle.historial.map((h) => (
            <li key={h.idHistorial} className="relative text-sm">
              <span className="absolute -left-[1.6rem] top-1.5 h-2.5 w-2.5 rounded-full bg-indigo-500" />
              <div className="flex flex-wrap items-center gap-2">
                <InsigniaEstado estado={h.estadoNuevo} />
                <span className="text-gray-500">{formatearFechaHora(h.fecha)}</span>
                {mostrarCliente && <span className="text-gray-400">· {h.correoUsuario}</span>}
              </div>
              {h.comentario && <p className="mt-1 text-gray-600">{h.comentario}</p>}
            </li>
          ))}
        </ol>
      </section>

      {detalle.devoluciones.length > 0 && (
        <section aria-labelledby="titulo-devoluciones">
          <h2 id="titulo-devoluciones" className="mb-3 text-lg font-semibold">
            Devoluciones
          </h2>
          <ul className="space-y-3">
            {detalle.devoluciones.map((d) => (
              <li key={d.idDevolucion} className="rounded-lg border border-gray-200 bg-white p-4 text-sm">
                <div className="flex flex-wrap justify-between gap-2">
                  <span className="font-medium">{formatearFechaHora(d.fecha)}</span>
                  <span className="font-medium">{formatearMoneda(d.montoReembolso)}</span>
                </div>
                <p className="text-gray-600">Motivo: {d.motivo}</p>
                <ul className="mt-2 list-disc pl-5 text-gray-600">
                  {detalle.detalleDevoluciones
                    .filter((l) => l.idDevolucion === d.idDevolucion)
                    .map((l) => (
                      <li key={l.idDetallePedido}>
                        {l.cantidad} × {l.nombreProducto} (SKU {l.sku})
                      </li>
                    ))}
                </ul>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}