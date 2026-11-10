import { Link, useParams } from 'react-router-dom';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { AccionesGestionPedido } from '../componentes/AccionesGestionPedido';
import { DetallePedidoVista } from '../componentes/DetallePedidoVista';
import { useDetallePedido } from '../hooks/usePedidos';

export function PaginaDetallePedidoGestion() {
  const { idPedido } = useParams();
  const id = Number(idPedido);
  const idValido = Number.isInteger(id) && id > 0;

  const consulta = useDetallePedido(idValido ? id : undefined);

  const enlaceVolver = (
    <Link to="/gestion/pedidos" className="inline-flex min-h-10 items-center text-sm font-medium text-marca-700 hover:underline">
      ← Volver a pedidos
    </Link>
  );

  if (!idValido) {
    return (
      <main className="mx-auto max-w-5xl px-4 py-6 sm:px-6 sm:py-8">
        <EstadoError error={new Error('El pedido solicitado no es válido.')} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  if (consulta.isPending) return <EstadoCarga mensaje="Cargando el pedido..." />;

  if (consulta.isError) {
    return (
      <main className="mx-auto max-w-5xl px-4 py-6 sm:px-6 sm:py-8">
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-5xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      {enlaceVolver}
      <AccionesGestionPedido detalle={consulta.data} />
      <DetallePedidoVista detalle={consulta.data} mostrarCliente />
    </main>
  );
}