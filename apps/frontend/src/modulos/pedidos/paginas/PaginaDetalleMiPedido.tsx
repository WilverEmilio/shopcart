import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda } from '../../../utilidades/formato';
import { DetallePedidoVista } from '../componentes/DetallePedidoVista';
import { DialogoCancelacion } from '../componentes/DialogoCancelacion';
import { useAccionesPedido, useDetallePedido } from '../hooks/usePedidos';

export function PaginaDetalleMiPedido() {
  const { idPedido } = useParams();
  const id = Number(idPedido);
  const idValido = Number.isInteger(id) && id > 0;

  const consulta = useDetallePedido(idValido ? id : undefined);
  const { cancelar } = useAccionesPedido();
  const [dialogoAbierto, setDialogoAbierto] = useState(false);

  const enlaceVolver = (
    <Link to="/mis-pedidos" className="inline-flex min-h-10 items-center text-sm font-medium text-marca-700 hover:underline">
      ← Volver a mis pedidos
    </Link>
  );

  if (!idValido) {
    return (
      <main className="mx-auto max-w-4xl px-4 py-6 sm:px-6">
        <EstadoError error={new Error('El pedido solicitado no es válido.')} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  if (consulta.isPending) return <EstadoCarga mensaje="Cargando el pedido..." />;

  if (consulta.isError) {
    return (
      <main className="mx-auto max-w-4xl px-4 py-6 sm:px-6">
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  const detalle = consulta.data;
  const puedeCancelar = detalle.estado === 'PAGADO';

  return (
    <main className="mx-auto max-w-5xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      {enlaceVolver}

      {cancelar.isSuccess && (
        <p role="status" className="rounded-tarjeta border border-green-200 bg-green-50 p-3 text-sm text-green-800">
          Tu pedido fue cancelado. Se reembolsarán {formatearMoneda(cancelar.data.montoReembolso)}.
        </p>
      )}

      <DetallePedidoVista detalle={detalle} />

      {puedeCancelar && (
        <section className="tarjeta flex flex-col gap-3 p-5 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-slate-600">
            Puedes cancelar tu pedido mientras no haya empezado a prepararse.
          </p>
          <Boton
            variante="peligro"
            onClick={() => {
              cancelar.reset();
              setDialogoAbierto(true);
            }}
          >
            Cancelar pedido
          </Boton>
        </section>
      )}

      <DialogoCancelacion
        abierto={dialogoAbierto}
        alCerrar={() => setDialogoAbierto(false)}
        cargando={cancelar.isPending}
        error={cancelar.isError ? normalizarError(cancelar.error).mensaje : null}
        alConfirmar={(motivo) =>
          cancelar.mutate({ idPedido: detalle.idPedido, motivo }, { onSuccess: () => setDialogoAbierto(false) })
        }
      />
    </main>
  );
}