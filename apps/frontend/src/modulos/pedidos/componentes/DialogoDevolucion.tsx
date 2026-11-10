import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { Modal } from '../../../componentes/Modal';
import type { DatosDevolucion, LineaPedido } from '../tipos/pedido';

interface Propiedades {
  abierto: boolean;
  alCerrar: () => void;
  items: LineaPedido[];
  alConfirmar: (datos: DatosDevolucion) => void;
  cargando: boolean;
  error: string | null;
}

function FormularioDevolucion({ items, alCerrar, alConfirmar, cargando, error }: Omit<Propiedades, 'abierto'>) {
  const pendientes = items.filter((i) => i.cantidad > i.cantidadDevuelta);

  const [modo, setModo] = useState<'total' | 'parcial'>('total');
  const [cantidades, setCantidades] = useState<Record<number, number>>({});
  const [motivo, setMotivo] = useState('');
  const [errorLocal, setErrorLocal] = useState<string | null>(null);

  const cambiarCantidad = (linea: LineaPedido, valor: number) => {
    const maximo = linea.cantidad - linea.cantidadDevuelta;
    const limpio = Math.min(Math.max(0, Math.trunc(valor) || 0), maximo);
    setCantidades((previas) => ({ ...previas, [linea.idDetallePedido]: limpio }));
  };

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();

    if (!motivo.trim()) {
      setErrorLocal('El motivo es obligatorio.');
      return;
    }

    const lineas = pendientes
      .map((i) => ({ idDetallePedido: i.idDetallePedido, cantidad: cantidades[i.idDetallePedido] ?? 0 }))
      .filter((l) => l.cantidad > 0);

    if (modo === 'parcial' && lineas.length === 0) {
      setErrorLocal('Indica al menos una unidad a devolver.');
      return;
    }

    setErrorLocal(null);
    alConfirmar({ motivo: motivo.trim(), devolverTodo: modo === 'total', lineas: modo === 'total' ? [] : lineas });
  };

  const mensaje = errorLocal ?? error;

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <fieldset className="space-y-2 text-sm">
        <legend className="mb-1 font-medium text-slate-700">Tipo de devolución</legend>
        <label className="flex min-h-10 cursor-pointer items-center gap-2">
          <input type="radio" name="modo" checked={modo === 'total'} onChange={() => setModo('total')} />
          Total (todas las unidades pendientes)
        </label>
        <label className="flex min-h-10 cursor-pointer items-center gap-2">
          <input type="radio" name="modo" checked={modo === 'parcial'} onChange={() => setModo('parcial')} />
          Parcial (elegir unidades por producto)
        </label>
      </fieldset>

      {modo === 'parcial' && (
        <ul className="space-y-2">
          {pendientes.map((i) => {
            const maximo = i.cantidad - i.cantidadDevuelta;
            return (
              <li key={i.idDetallePedido} className="flex items-center justify-between gap-3 text-sm">
                <span>
                  {i.nombreProducto}
                  <span className="block text-xs text-slate-600">
                    SKU {i.sku} · se pueden devolver hasta {maximo}
                  </span>
                </span>
                <input
                  type="number"
                  min={0}
                  max={maximo}
                  aria-label={`Unidades a devolver de ${i.nombreProducto}`}
                  value={cantidades[i.idDetallePedido] ?? 0}
                  onChange={(e) => cambiarCantidad(i, Number(e.target.value))}
                  inputMode="numeric"
                  className="control w-20 shrink-0 text-center"
                />
              </li>
            );
          })}
        </ul>
      )}

      <div>
        <label htmlFor="motivo-devolucion" className="mb-1 block text-sm font-medium text-slate-700">
          Motivo
        </label>
        <textarea
          id="motivo-devolucion"
          rows={3}
          maxLength={255}
          value={motivo}
          onChange={(e) => setMotivo(e.target.value)}
          className="control"
        />
      </div>

      <p className="text-xs text-slate-500">
        El reembolso se calcula en el servidor, respetando los descuentos del pedido, y las unidades regresan al inventario.
      </p>

      {mensaje && (
        <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {mensaje}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={cargando}>
          Cancelar
        </Boton>
        <Boton type="submit" cargando={cargando}>
          Registrar devolución
        </Boton>
      </div>
    </form>
  );
}

export function DialogoDevolucion({ abierto, alCerrar, ...resto }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo="Registrar devolución" alCerrar={alCerrar}>
      <FormularioDevolucion alCerrar={alCerrar} {...resto} />
    </Modal>
  );
}