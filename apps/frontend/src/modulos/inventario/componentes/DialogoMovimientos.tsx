import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { Modal } from '../../../componentes/Modal';
import { normalizarError } from '../../../servicios/errorServicio';
import { useMovimientosInventario } from '../hooks/useInventario';
import type { ExistenciaVariante } from '../tipos/inventario';

export type TipoDialogoMovimiento = 'entrada' | 'ajuste';

interface Propiedades {
  variante: ExistenciaVariante | null;
  tipo: TipoDialogoMovimiento;
  alCerrar: () => void;
  alRegistrado: (mensaje: string) => void;
}

function FormularioMovimiento({
  variante,
  tipo,
  alCerrar,
  alRegistrado,
}: Omit<Propiedades, 'variante'> & { variante: ExistenciaVariante }) {
  const { entrada, ajuste } = useMovimientosInventario();
  const mutacion = tipo === 'entrada' ? entrada : ajuste;

  const [cantidad, setCantidad] = useState('');
  const [motivo, setMotivo] = useState('');
  const [errorLocal, setErrorLocal] = useState<string | null>(null);

  const valor = Number(cantidad);
  const numeroValido = cantidad.trim() !== '' && Number.isInteger(valor);
  const resultante = numeroValido ? variante.existenciaFisica + valor : null;

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();

    if (!numeroValido || valor === 0) {
      setErrorLocal('Ingresa una cantidad entera distinta de cero.');
      return;
    }
    if (tipo === 'entrada' && valor < 0) {
      setErrorLocal('La cantidad de una entrada debe ser positiva.');
      return;
    }
    if (!motivo.trim()) {
      setErrorLocal('El motivo es obligatorio.');
      return;
    }
    if (resultante !== null && resultante < 0) {
      setErrorLocal('El ajuste dejaría la existencia física en negativo.');
      return;
    }

    setErrorLocal(null);
    mutacion.mutate(
      { idVariante: variante.idVariante, cantidad: valor, motivo: motivo.trim() },
      {
        onSuccess: (r) => {
          alRegistrado(`${variante.sku}: existencia física ${r.existenciaAnterior} → ${r.existenciaNueva}.`);
          alCerrar();
        },
      }
    );
  };

  const mensaje = errorLocal ?? (mutacion.isError ? normalizarError(mutacion.error).mensaje : null);

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <div className="rounded-control bg-gray-50 p-3 text-sm">
        <p className="font-medium">{variante.producto}</p>
        <p className="text-gray-500">
          SKU {variante.sku} · Física {variante.existenciaFisica} · Reservada {variante.existenciaReservada} · Disponible{' '}
          {variante.existenciaDisponible}
        </p>
      </div>

      <div>
        <label htmlFor="cantidad-movimiento" className="mb-1.5 block text-sm font-medium text-gray-700">
          {tipo === 'entrada' ? 'Unidades que ingresan' : 'Ajuste (positivo suma, negativo resta)'}
        </label>
        <input
          id="cantidad-movimiento"
          type="number"
          step={1}
          min={tipo === 'entrada' ? 1 : undefined}
          value={cantidad}
          onChange={(e) => setCantidad(e.target.value)}
          className="control w-40"
        />
        {resultante !== null && (
          <p className={`mt-1 text-sm ${resultante < 0 ? 'text-red-600' : 'text-gray-500'}`}>
            Existencia física resultante: {resultante}
          </p>
        )}
      </div>

      <div>
        <label htmlFor="motivo-movimiento" className="mb-1.5 block text-sm font-medium text-gray-700">
          Motivo
        </label>
        <textarea
          id="motivo-movimiento"
          rows={3}
          maxLength={255}
          placeholder={tipo === 'entrada' ? 'Ej.: Compra a proveedor, factura 1234' : 'Ej.: Conteo físico: faltan 2 unidades'}
          value={motivo}
          onChange={(e) => setMotivo(e.target.value)}
          className="control"
        />
      </div>

      {tipo === 'ajuste' && (
        <p className="text-xs text-gray-500">
          El kardex no se puede editar ni borrar: cualquier corrección se hace con un ajuste que queda registrado.
        </p>
      )}

      {mensaje && (
        <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {mensaje}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={mutacion.isPending}>
          Cancelar
        </Boton>
        <Boton type="submit" cargando={mutacion.isPending}>
          {tipo === 'entrada' ? 'Registrar entrada' : 'Registrar ajuste'}
        </Boton>
      </div>
    </form>
  );
}

export function DialogoMovimiento({ variante, tipo, alCerrar, alRegistrado }: Propiedades) {
  return (
    <Modal
      abierto={variante !== null}
      titulo={tipo === 'entrada' ? 'Registrar entrada de inventario' : 'Registrar ajuste de inventario'}
      alCerrar={alCerrar}
    >
      {variante && <FormularioMovimiento variante={variante} tipo={tipo} alCerrar={alCerrar} alRegistrado={alRegistrado} />}
    </Modal>
  );
}