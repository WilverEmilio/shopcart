import { useState } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { normalizarError } from '../../../servicios/errorServicio';
import { ACCION_AVANCE, esEstadoAvance } from '../constante';
import { useAccionesPedido, useTransiciones } from '../hooks/usePedidos';
import type { DetallePedido } from '../tipos/pedido';
import { DialogoCancelacion } from './DialogoCancelacion';
import { DialogoDevolucion } from './DialogoDevolucion';

export function AccionesGestionPedido({ detalle }: { detalle: DetallePedido }) {
  const transiciones = useTransiciones();
  const { cancelar, avanzar, devolver } = useAccionesPedido();

  const [comentario, setComentario] = useState('');
  const [dialogo, setDialogo] = useState<'cancelar' | 'devolver' | null>(null);

  // Solo se ofrece lo que la tabla de transiciones permite desde el estado actual
  const destinos = (transiciones.data ?? []).filter((t) => t.origen === detalle.estado).map((t) => t.destino);
  const avances = destinos.filter(esEstadoAvance);
  const puedeCancelar = destinos.includes('CANCELADO');
  const puedeDevolver =
    (detalle.estado === 'ENTREGADO' || detalle.estado === 'DEVUELTO_PARCIAL') &&
    detalle.items.some((i) => i.cantidad > i.cantidadDevuelta);

  const sinAcciones = avances.length === 0 && !puedeCancelar && !puedeDevolver;

  const abrir = (cual: 'cancelar' | 'devolver') => {
    cancelar.reset();
    devolver.reset();
    setDialogo(cual);
  };

  return (
    <section aria-labelledby="titulo-acciones" className="tarjeta space-y-4 p-4 sm:p-5">
      <h2 id="titulo-acciones" className="text-lg font-semibold">
        Acciones
      </h2>

      {transiciones.isPending ? (
        <p className="text-sm text-slate-600">Cargando acciones disponibles...</p>
      ) : sinAcciones ? (
        <p className="text-sm text-slate-600">No hay acciones disponibles para un pedido en este estado.</p>
      ) : (
        <>
          {avances.length > 0 && (
            <div className="space-y-3">
              <CampoFormulario
                etiqueta="Comentario (opcional)"
                maxLength={255}
                value={comentario}
                onChange={(e) => setComentario(e.target.value)}
              />
              <div className="flex flex-wrap gap-2">
                {avances.map((estado) => (
                  <Boton
                    key={estado}
                    cargando={avanzar.isPending}
                    onClick={() => {
                      avanzar.reset();
                      avanzar.mutate(
                        { idPedido: detalle.idPedido, estado, comentario: comentario.trim() || null },
                        { onSuccess: () => setComentario('') }
                      );
                    }}
                  >
                    {ACCION_AVANCE[estado]}
                  </Boton>
                ))}
              </div>
            </div>
          )}

          {avanzar.isError && (
            <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
              {normalizarError(avanzar.error).mensaje}
            </p>
          )}

          <div className="flex flex-wrap gap-2">
            {puedeCancelar && (
              <Boton variante="peligro" onClick={() => abrir('cancelar')}>
                Cancelar pedido
              </Boton>
            )}
            {puedeDevolver && (
              <Boton variante="secundario" onClick={() => abrir('devolver')}>
                Registrar devolución
              </Boton>
            )}
          </div>
        </>
      )}

      <DialogoCancelacion
        abierto={dialogo === 'cancelar'}
        alCerrar={() => setDialogo(null)}
        cargando={cancelar.isPending}
        error={cancelar.isError ? normalizarError(cancelar.error).mensaje : null}
        alConfirmar={(motivo) =>
          cancelar.mutate({ idPedido: detalle.idPedido, motivo }, { onSuccess: () => setDialogo(null) })
        }
      />

      <DialogoDevolucion
        abierto={dialogo === 'devolver'}
        alCerrar={() => setDialogo(null)}
        items={detalle.items}
        cargando={devolver.isPending}
        error={devolver.isError ? normalizarError(devolver.error).mensaje : null}
        alConfirmar={(datos) =>
          devolver.mutate({ idPedido: detalle.idPedido, datos }, { onSuccess: () => setDialogo(null) })
        }
      />
    </section>
  );
}