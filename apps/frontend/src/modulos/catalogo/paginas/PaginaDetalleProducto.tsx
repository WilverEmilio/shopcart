import { useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { Esqueleto } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import { formatearMoneda } from '../../../utilidades/formato';
import { useDetalleProducto } from '../hooks/useCatalogo';
import type { ProductoDetalle } from '../tipos/catalogo';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { normalizarError } from '../../../servicios/errorServicio';
import { useAccionesCarrito } from '../../carrito/hooks/useCarrito';

const claseBotonCantidad =
  'flex h-11 w-11 items-center justify-center text-lg text-slate-700 transition-colors hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent';

function MigasDePan({ categoria, nombre }: { categoria?: string; nombre?: string }) {
  return (
    <nav aria-label="Ruta de navegación" className="text-sm">
      <ol className="flex min-w-0 items-center gap-2 text-slate-600">
        <li>
          <Link to="/catalogo" className="font-medium text-marca-700 hover:underline">
            Catálogo
          </Link>
        </li>
        {categoria && (
          <>
            <li aria-hidden="true">/</li>
            <li className="hidden sm:block">{categoria}</li>
            <li aria-hidden="true" className="hidden sm:block">/</li>
          </>
        )}
        {nombre && (
          <li aria-current="page" className="min-w-0 truncate text-slate-900">
            {nombre}
          </li>
        )}
      </ol>
    </nav>
  );
}

function DetalleProducto({ detalle }: { detalle: ProductoDetalle }) {
  const { producto, imagenes, variantes, atributos } = detalle;

  const imagenesOrdenadas = useMemo(
    () => [...imagenes].sort((a, b) => Number(b.esPrincipal) - Number(a.esPrincipal) || a.orden - b.orden),
    [imagenes]
  );

  const etiquetas = useMemo(() => {
    const mapa = new Map<number, string>();
    for (const v of variantes) {
      const partes = atributos
        .filter((a) => a.idVariante === v.idVariante)
        .map((a) => `${a.atributo}: ${a.valor}`);
      mapa.set(v.idVariante, partes.length > 0 ? partes.join(' · ') : v.sku);
    }
    return mapa;
  }, [variantes, atributos]);

  const [indiceImagen, setIndiceImagen] = useState(0);
  const [idVarianteElegida, setIdVarianteElegida] = useState<number | undefined>(
    () => (variantes.find((v) => v.existenciaDisponible > 0) ?? variantes[0])?.idVariante
  );
  const [cantidad, setCantidad] = useState(1);

  const usuario = useSesionEstado((e) => e.usuario);
  const { agregar } = useAccionesCarrito();
  const puedeComprar = !usuario || usuario.rol === 'Cliente';
  const [aviso, setAviso] = useState<string | null>(null);

  const agregarAlCarrito = () => {
    if (!variante) return;
    setAviso(null);
    agregar.mutate(
      { idVariante: variante.idVariante, cantidad },
      { onSuccess: () => setAviso('Producto agregado al carrito.') }
    );
  };

  const variante = variantes.find((v) => v.idVariante === idVarianteElegida);
  const disponible = variante?.existenciaDisponible ?? 0;
  const agotada = disponible <= 0;
  const imagenActual = imagenesOrdenadas[indiceImagen] ?? null;

  const cambiarCantidad = (valor: number) => {
    if (Number.isNaN(valor)) return;
    setCantidad(Math.min(Math.max(1, Math.trunc(valor)), Math.max(1, disponible)));
  };

  const elegirVariante = (id: number) => {
    setIdVarianteElegida(id);
    setCantidad(1);
    setAviso(null);
    agregar.reset();
  };

  const estadoStock = agotada
    ? { texto: 'Agotado', clase: 'bg-red-50 text-red-700', punto: 'bg-red-500' }
    : disponible <= 5
      ? { texto: `Quedan ${disponible} unidades`, clase: 'bg-amber-50 text-amber-800', punto: 'bg-amber-500' }
      : { texto: 'Disponible', clase: 'bg-green-50 text-green-800', punto: 'bg-green-500' };

  return (
    <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 sm:py-8">
      <MigasDePan categoria={producto.categoria} nombre={producto.nombre} />

      <div className="mt-6 grid gap-8 md:grid-cols-2 lg:gap-12">
        <div className="md:sticky md:top-20 md:self-start">
          <div className="tarjeta aspect-square overflow-hidden bg-white">
            <ImagenProducto url={imagenActual?.url ?? null} alt={producto.nombre} className="h-full w-full object-contain" />
          </div>

          {imagenesOrdenadas.length > 1 && (
            <ul className="mt-3 flex gap-2 overflow-x-auto pb-1">
              {imagenesOrdenadas.map((img, i) => (
                <li key={img.idImagenProducto} className="shrink-0">
                  <button
                    type="button"
                    aria-label={`Ver imagen ${i + 1}`}
                    aria-current={i === indiceImagen}
                    onClick={() => setIndiceImagen(i)}
                    className={`h-16 w-16 overflow-hidden rounded-control border-2 bg-white transition-colors sm:h-20 sm:w-20 ${
                      i === indiceImagen ? 'border-marca-600' : 'border-slate-200 hover:border-slate-400'
                    }`}
                  >
                    <ImagenProducto url={img.url} alt="" className="h-full w-full object-cover" />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div>
          <p className="text-sm font-semibold text-marca-700">{producto.categoria}</p>
          <h1 className="mt-1 text-3xl font-bold sm:text-4xl">{producto.nombre}</h1>

          {variante && (
            <div className="mt-4 flex flex-wrap items-baseline gap-x-3 gap-y-1">
              <p className="precio text-3xl sm:text-4xl">{formatearMoneda(variante.precio)}</p>
              <p className="text-sm text-slate-600">IVA incluido</p>
            </div>
          )}

          {producto.descripcion && (
            <p className="mt-5 whitespace-pre-line leading-relaxed text-slate-700">{producto.descripcion}</p>
          )}

          {variantes.length > 0 && (
            <fieldset className="mt-6">
              <legend className="mb-2 text-sm font-medium text-slate-900">
                {variantes.length > 1 ? 'Elige una opción' : 'Presentación'}
              </legend>
              <div className="flex flex-wrap gap-2">
                {variantes.map((v) => {
                  const elegida = v.idVariante === idVarianteElegida;
                  const sinStock = v.existenciaDisponible <= 0;
                  return (
                    <button
                      key={v.idVariante}
                      type="button"
                      aria-pressed={elegida}
                      onClick={() => elegirVariante(v.idVariante)}
                      className={`inline-flex min-h-11 items-center gap-2 rounded-control border px-4 text-sm font-medium transition-colors duration-150 motion-reduce:transition-none ${
                        elegida
                          ? 'border-marca-600 bg-marca-50 text-marca-800 ring-1 ring-marca-600'
                          : 'border-slate-300 bg-white text-slate-700 hover:border-slate-400'
                      } ${sinStock ? 'text-slate-500 line-through decoration-slate-400' : ''}`}
                    >
                      {elegida && (
                        <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="h-4 w-4">
                          <path strokeLinecap="round" strokeLinejoin="round" d="m5 12 5 5L20 7" />
                        </svg>
                      )}
                      {etiquetas.get(v.idVariante)}
                      {sinStock && <span className="sr-only"> (agotado)</span>}
                    </button>
                  );
                })}
              </div>
            </fieldset>
          )}

          <div className="tarjeta mt-6 space-y-4 p-4 sm:p-5">
            {variante && (
              <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
                <span className={`inline-flex items-center gap-2 rounded-full px-3 py-1 font-medium ${estadoStock.clase}`}>
                  <span aria-hidden="true" className={`h-2 w-2 rounded-full ${estadoStock.punto}`} />
                  {estadoStock.texto}
                </span>
                <span className="text-slate-600">SKU {variante.sku}</span>
              </div>
            )}

            <div className="flex flex-wrap items-end gap-3">
              <div>
                <label htmlFor="cantidad" className="mb-1.5 block text-sm font-medium text-slate-700">
                  Cantidad
                </label>
                <div className="inline-flex items-center overflow-hidden rounded-control border border-slate-300 bg-white">
                  <button
                    type="button"
                    aria-label="Disminuir cantidad"
                    className={claseBotonCantidad}
                    disabled={agotada || cantidad <= 1}
                    onClick={() => cambiarCantidad(cantidad - 1)}
                  >
                    −
                  </button>
                  <input
                    id="cantidad"
                    type="number"
                    inputMode="numeric"
                    min={1}
                    max={Math.max(1, disponible)}
                    value={cantidad}
                    disabled={agotada}
                    onChange={(e) => cambiarCantidad(Number(e.target.value))}
                    className="h-11 w-14 border-x border-slate-300 text-center text-base tabular-nums outline-none [appearance:textfield] focus:bg-marca-50 disabled:bg-slate-100 sm:text-sm [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
                  />
                  <button
                    type="button"
                    aria-label="Aumentar cantidad"
                    className={claseBotonCantidad}
                    disabled={agotada || cantidad >= disponible}
                    onClick={() => cambiarCantidad(cantidad + 1)}
                  >
                    +
                  </button>
                </div>
              </div>

              {puedeComprar && (
                <Boton onClick={agregarAlCarrito} disabled={agotada} cargando={agregar.isPending} className="h-11 min-w-48 flex-1">
                  {agotada ? 'Agotado' : 'Agregar al carrito'}
                </Boton>
              )}
            </div>

            {!puedeComprar && <p className="text-sm text-slate-600">Las cuentas de gestión no realizan compras.</p>}

            {aviso && (
              <p role="status" className="flex flex-wrap items-center gap-x-2 rounded-control bg-green-50 p-3 text-sm text-green-800">
                <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="h-4 w-4">
                  <path strokeLinecap="round" strokeLinejoin="round" d="m5 12 5 5L20 7" />
                </svg>
                {aviso}
                <Link to="/carrito" className="font-semibold underline underline-offset-2">
                  Ver carrito
                </Link>
              </p>
            )}

            {agregar.isError && (
              <p role="alert" className="rounded-control bg-red-50 p-3 text-sm text-red-700">
                {normalizarError(agregar.error).mensaje}
              </p>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}

function DetalleProductoEsqueleto() {
  return (
    <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 sm:py-8">
      <div role="status">
        <span className="sr-only">Cargando producto...</span>
        <Esqueleto className="h-4 w-40" />
        <div className="mt-6 grid gap-8 md:grid-cols-2 lg:gap-12">
          <Esqueleto className="aspect-square rounded-tarjeta" />
          <div className="space-y-4">
            <Esqueleto className="h-3 w-24" />
            <Esqueleto className="h-8 w-3/4" />
            <Esqueleto className="h-9 w-40" />
            <Esqueleto className="h-20 w-full" />
            <Esqueleto className="h-32 w-full rounded-tarjeta" />
          </div>
        </div>
      </div>
    </main>
  );
}

export function PaginaDetalleProducto() {
  const { idProducto } = useParams();
  const id = Number(idProducto);
  const idValido = Number.isInteger(id) && id > 0;

  const consulta = useDetalleProducto(idValido ? id : undefined);

  if (!idValido) {
    return (
      <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
        <MigasDePan />
        <EstadoError error={new Error('El producto solicitado no es válido.')} />
      </main>
    );
  }

  if (consulta.isPending) return <DetalleProductoEsqueleto />;

  if (consulta.isError) {
    return (
      <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6">
        <MigasDePan />
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      </main>
    );
  }

  return <DetalleProducto key={consulta.data.producto.idProducto} detalle={consulta.data} />;
}
