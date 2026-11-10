import { Boton } from './Boton';
import { Modal } from './Modal';

interface Propiedades {
  abierto: boolean;
  titulo: string;
  mensaje: string;
  textoConfirmar: string;
  peligro?: boolean;
  cargando: boolean;
  error: string | null;
  alConfirmar: () => void;
  alCerrar: () => void;
}

export function DialogoConfirmacion({
  abierto, titulo, mensaje, textoConfirmar, peligro = false, cargando, error, alConfirmar, alCerrar,
}: Propiedades) {
  return (
    <Modal abierto={abierto} titulo={titulo} alCerrar={alCerrar}>
      <div className="space-y-4">
        <p className="text-sm text-slate-600">{mensaje}</p>

        {error && (
          <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2">
          <Boton variante="secundario" onClick={alCerrar} disabled={cargando}>
            Cancelar
          </Boton>
          <Boton variante={peligro ? 'peligro' : 'primario'} cargando={cargando} onClick={alConfirmar}>
            {textoConfirmar}
          </Boton>
        </div>
      </div>
    </Modal>
  );
}