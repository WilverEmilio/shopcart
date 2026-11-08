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
            1. Dirección de entrega
          </h2>

          {listaDirecciones.map((d) => {
            const elegida = d.idDireccion === idDireccion;
            return (
              <label
                key={d.idDireccion}
                className={`flex cursor-pointer gap-3 rounded-lg border p-4 ${
                  elegida ? 'border-indigo-600 bg-indigo-50' : 'border-gray-200 bg-white'
                }`}
              >
                <input
                  type="radio"
                  name="direccion"
                  className="mt-1"
                  checked={elegida}
                  onChange={() => setIdDireccionElegida(d.idDireccion)}
                />
                <span className="text-sm">
                  <span className="block font-medium">
                    {d.nombreDestinatario}
                    {d.esPredeterminada && (
                      <span className="ml-2 rounded bg-gray-200 px-2 py-0.5 text-xs font-normal">Predeterminada</span>
                    )}
                  </span>
                  <span className="block text-gray-600">
                    {d.direccion}, {d.municipio}, {d.departamento}
                  </span>
                  {d.referencia && <span className="block text-gray-500">Ref.: {d.referencia}</span>}
                  <span className="block text-gray-500">Tel. {d.telefono}</span>
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
              Agregar otra dirección
            </Boton>
          )}
        </section>

        <section aria-labelledby="titulo-envio" className="space-y-3">
          <h2 id="titulo-envio" className="text-lg font-semibold">
            2. Método de envío
          </h2>

          {listaEnvios.map((e) => {
            const elegido = e.idMetodoEnvio === idEnvio;
            return (
              <label
                key={e.idMetodoEnvio}
                className={`flex cursor-pointer items-start justify-between gap-3 rounded-lg border p-4 ${
                  elegido ? 'border-indigo-600 bg-indigo-50' : 'border-gray-200 bg-white'
                }`}
              >
                <span className="flex gap-3">
                  <input
                    type="radio"
                    name="envio"
                    className="mt-1"
                    checked={elegido}
                    onChange={() => setIdEnvioElegido(e.idMetodoEnvio)}
                  />
                  <span className="text-sm">
                    <span className="block font-medium">{e.nombre}</span>
                    {e.descripcion && <span className="block text-gray-600">{e.descripcion}</span>}
                    <span className="block text-gray-500">
                      Entrega estimada: {e.diasEstaimados} {e.diasEstaimados === 1 ? 'día' : 'días'}
                    </span>
                  </span>
                </span>
                <span className="text-sm font-medium">{e.costo === 0 ? 'Gratis' : formatearMoneda(e.costo)}</span>
              </label>
            );
          })}
        </section>
      </div>

      <div className="space-y-4 lg:self-start">
        <ResumenPedido carrito={carrito} envio={envio?.costo ?? null} total={totalEstimado} />

        {iniciar.isError && (
          <div role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
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
        <p className="text-xs text-gray-500">
          Al continuar reservaremos tus productos durante 15 minutos mientras completas el pago.
        </p>
      </div>
    </div>
  );
}