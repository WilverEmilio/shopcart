import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { Modal } from '../../../componentes/Modal';

interface Propiedades {
  abierto: boolean;
  alCerrar: () => void;
  alConfirmar: (motivo: string) => void;
  cargando: boolean;
  error: string | null;
}

function FormularioMotivo({ alCerrar, alConfirmar, cargando, error }: Omit<Propiedades, 'abierto'>) {
  const [motivo, setMotivo] = useState('');
  const [errorLocal, setErrorLocal] = useState<string | null>(null);

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    if (!motivo.trim()) {
      setErrorLocal('El motivo es obligatorio.');
      return;
    }
    setErrorLocal(null);
    alConfirmar(motivo.trim());
  };

  const mensaje = errorLocal ?? error;

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <p className="text-sm text-gray-600">
        Al cancelar, las unidades vuelven al inventario y se revierte el uso del cupón. Esta acción no se puede deshacer.
      </p>

      <div>
        <label htmlFor="motivo-cancelacion" className="mb-1 block text-sm font-medium text-gray-700">
          Motivo de la cancelación
        </label>
        <textarea
          id="motivo-cancelacion"
          rows={3}
          maxLength={255}
          value={motivo}
          onChange={(e) => setMotivo(e.target.value)}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
        />
      </div>

      {mensaje && (
        <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {mensaje}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={cargando}>
          Volver
        </Boton>
        <Boton type="submit" variante="peligro" cargando={cargando}>
          Cancelar pedido
        </Boton>
      </div>
    </form>
  );
}

export function DialogoCancelacion({ abierto, alCerrar, ...resto }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo="Cancelar pedido" alCerrar={alCerrar}>
      <FormularioMotivo alCerrar={alCerrar} {...resto} />
    </Modal>
  );
}