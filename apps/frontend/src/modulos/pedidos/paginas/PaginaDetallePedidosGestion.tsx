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
    <Link to="/gestion/pedidos" className="text-sm text-indigo-600 hover:underline">
      ← Volver a pedidos
    </Link>
  );

  if (!idValido) {
    return (
      <main className="mx-auto max-w-5xl p-6">
        <EstadoError error={new Error('El pedido solicitado no es válido.')} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  if (consulta.isPending) return <EstadoCarga mensaje="Cargando el pedido..." />;

  if (consulta.isError) {
    return (
      <main className="mx-auto max-w-5xl p-6">
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-5xl space-y-6 p-6">
      {enlaceVolver}
      <AccionesGestionPedido detalle={consulta.data} />
      <DetallePedidoVista detalle={consulta.data} mostrarCliente />
    </main>
  );
}