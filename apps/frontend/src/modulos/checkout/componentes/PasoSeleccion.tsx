import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';
import { Boton } from '../../../componentes/Boton';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda, redondear } from '../../../utilidades/formato';
import { CLAVE_CARRITO } from '../../carrito/constantes';
import type { Carrito } from '../../carrito/tipos/carrito';
import { FormularioDireccion } from '../../direcciones/componentes/FormularioDireccion';
import { useDirecciones } from '../../direcciones/hooks/useDirecciones';
import { useIniciarPago, useMetodosEnvio } from '../hooks/useCheckout';
import { ResumenPedido } from './ResumenPedido';

export function PasoSeleccion({ carrito }: { carrito: Carrito }) {
  const cliente = useQueryClient();
  const direcciones = useDirecciones();
  const envios = useMetodosEnvio();
  const iniciar = useIniciarPago();

  const [idDireccionElegida, setIdDireccionElegida] = useState<number | null>(null);
  const [idEnvioElegido, setIdEnvioElegido] = useState<number | null>(null);
  const [agregando, setAgregando] = useState(false);

  if (direcciones.isPending || envios.isPending) return <EstadoCarga mensaje="Preparando tu compra..." />;
  if (direcciones.isError) return <EstadoError error={direcciones.error} onReintentar={() => void direcciones.refetch()} />;
  if (envios.isError) return <EstadoError error={envios.error} onReintentar={() => void envios.refetch()} />;

  const listaDirecciones = direcciones.data;
  const listaEnvios = envios.data;

  const idDireccion =
    idDireccionElegida ??
    (listaDirecciones.find((d) => d.esPredeterminada) ?? listaDirecciones[0])?.idDireccion ??
    null;
  const idEnvio = idEnvioElegido ?? listaEnvios[0]?.idMetodoEnvio ?? null;

  const envio = listaEnvios.find((e) => e.idMetodoEnvio === idEnvio) ?? null;
  const totalEstimado = redondear(carrito.total + (envio?.costo ?? 0));
  const mostrarFormulario = agregando || listaDirecciones.length === 0;

  const continuar = () => {
    if (idDireccion === null || idEnvio === null) return;

    iniciar.mutate(
      { idDireccion, idMetodoEnvio: idEnvio, totalEsperado: totalEstimado },
      {
        onError: () => void cliente.invalidateQueries({ queryKey: CLAVE_CARRITO }),
      }
    );
  };

  return (
    <div className="grid gap-8 lg:grid-cols-[1fr_22rem]">
      <div className="space-y-8">
        <section aria-labelledby="titulo-direccion" className="space-y-3">
          <h2 id="titulo-direccion" className="text-lg font-semibold">
            Dirección de entrega
          </h2>

          {listaDirecciones.map((d) => {
            const elegida = d.idDireccion === idDireccion;
            return (
              <label key={d.idDireccion} className="opcion-seleccionable">
                <input
                  type="radio"
                  name="direccion"
                  className="mt-0.5 h-4 w-4 shrink-0"
                  checked={elegida}
                  onChange={() => setIdDireccionElegida(d.idDireccion)}
                />
                <span className="min-w-0 text-sm">
                  <span className="flex flex-wrap items-center gap-2 font-medium text-slate-900">
                    {d.nombreDestinatario}
                    {d.esPredeterminada && (
                      <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-700">Predeterminada</span>
                    )}
                  </span>
                  <span className="block text-slate-600">
                    {d.direccion}, {d.municipio}, {d.departamento}
                  </span>
                  {d.referencia && <span className="block text-slate-600">Ref.: {d.referencia}</span>}
                  <span className="block text-slate-600">Tel. {d.telefono}</span>
                </span>
              </label>
            );
          })}

          {mostrarFormulario ? (
            <FormularioDireccion
              alGuardar={(id) => {
                setIdDireccionElegida(id);
                setAgregando(false);
              }}
              alCancelar={listaDirecciones.length > 0 ? () => setAgregando(false) : undefined}
            />
          ) : (
            <Boton variante="secundario" onClick={() => setAgregando(true)}>
              <span aria-hidden="true">+</span> Agregar otra dirección
            </Boton>
          )}
        </section>

        <section aria-labelledby="titulo-envio" className="space-y-3">
          <h2 id="titulo-envio" className="text-lg font-semibold">
            Método de envío
          </h2>

          {listaEnvios.map((e) => {
            const elegido = e.idMetodoEnvio === idEnvio;
            return (
              <label key={e.idMetodoEnvio} className="opcion-seleccionable items-start justify-between">
                <span className="flex gap-3">
                  <input
                    type="radio"
                    name="envio"
                    className="mt-0.5 h-4 w-4 shrink-0"
                    checked={elegido}
                    onChange={() => setIdEnvioElegido(e.idMetodoEnvio)}
                  />
                  <span className="text-sm">
                    <span className="block font-medium text-slate-900">{e.nombre}</span>
                    {e.descripcion && <span className="block text-slate-600">{e.descripcion}</span>}
                    <span className="block text-slate-600">
                      Entrega estimada: {e.diasEstaimados} {e.diasEstaimados === 1 ? 'día' : 'días'}
                    </span>
                  </span>
                </span>
                <span className={`shrink-0 text-sm font-semibold tabular-nums ${e.costo === 0 ? 'text-green-700' : 'text-slate-900'}`}>
                  {e.costo === 0 ? 'Gratis' : formatearMoneda(e.costo)}
                </span>
              </label>
            );
          })}
        </section>
      </div>

      <div className="space-y-4 lg:sticky lg:top-20 lg:self-start">
        <ResumenPedido carrito={carrito} envio={envio?.costo ?? null} total={totalEstimado} />

        {iniciar.isError && (
          <div role="alert" className="rounded-tarjeta border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            <p>{normalizarError(iniciar.error).mensaje}</p>
            <Link to="/carrito" className="mt-1 inline-block font-medium underline">
              Revisar mi carrito
            </Link>
          </div>
        )}

        <Boton
          className="w-full"
          cargando={iniciar.isPending}
          disabled={idDireccion === null || idEnvio === null}
          onClick={continuar}
        >
          Continuar al pago
        </Boton>
        <p className="text-xs text-slate-600">
          Al continuar reservaremos tus productos durante 15 minutos mientras completas el pago.
        </p>
      </div>
    </div>
  );
}
