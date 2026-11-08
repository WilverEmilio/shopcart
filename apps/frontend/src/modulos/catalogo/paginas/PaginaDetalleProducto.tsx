import { useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import { formatearMoneda } from '../../../utilidades/formato';
import { useDetalleProducto } from '../hooks/useCatalogo';
import type { ProductoDetalle } from '../tipos/catalogo';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { normalizarError } from '../../../servicios/errorServicio';
import { useAccionesCarrito } from '../../carrito/hooks/useCarrito';



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

  return (
    <main className="mx-auto max-w-7xl p-6">
      <Link to="/catalogo" className="text-sm text-indigo-600 hover:underline">
        ← Volver al catálogo
      </Link>

      <div className="mt-4 grid gap-8 md:grid-cols-2">
        <div>
          <div className="aspect-square overflow-hidden rounded-lg border border-gray-200 bg-gray-100">
            <ImagenProducto url={imagenActual?.url ?? null} alt={producto.nombre} className="h-full w-full object-contain" />
          </div>

          {imagenesOrdenadas.length > 1 && (
            <ul className="mt-3 flex gap-2 overflow-x-auto">
              {imagenesOrdenadas.map((img, i) => (
                <li key={img.idImagenProducto}>
                  <button
                    type="button"
                    aria-label={`Ver imagen ${i + 1}`}
                    aria-current={i === indiceImagen}
                    onClick={() => setIndiceImagen(i)}
                    className={`h-16 w-16 overflow-hidden rounded-md border-2 ${i === indiceImagen ? 'border-indigo-600' : 'border-transparent'}`}
                  >
                    <ImagenProducto url={img.url} alt="" className="h-full w-full object-cover" />
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div>
          <p className="text-sm uppercase tracking-wide text-gray-500">{producto.categoria}</p>
          <h1 className="mt-1 text-2xl font-semibold">{producto.nombre}</h1>

          {variante && (
            <>
              <p className="mt-4 text-3xl font-bold">{formatearMoneda(variante.precio)}</p>
              <p className="text-xs text-gray-500">IVA incluido</p>
            </>
          )}

          {producto.descripcion && <p className="mt-4 whitespace-pre-line text-gray-700">{producto.descripcion}</p>}

          {variantes.length > 0 && (
            <fieldset className="mt-6">
              <legend className="mb-2 text-sm font-medium text-gray-700">
                {variantes.length > 1 ? 'Elige una opción' : 'Presentación'}
              </legend>
              <div className="flex flex-wrap gap-2">
                {variantes.map((v) => {
                  const elegida = v.idVariante === idVarianteElegida;
                  return (
                    <button
                      key={v.idVariante}
                      type="button"
                      aria-pressed={elegida}
                      onClick={() => elegirVariante(v.idVariante)}
                      className={`rounded-md border px-3 py-2 text-sm ${
                        elegida ? 'border-indigo-600 bg-indigo-50 text-indigo-700' : 'border-gray-300 hover:bg-gray-100'
                      } ${v.existenciaDisponible <= 0 ? 'opacity-60' : ''}`}
                    >
                      {etiquetas.get(v.idVariante)}
                    </button>
                  );
                })}
              </div>
            </fieldset>
          )}

          {variante && (
            <p className={`mt-4 text-sm ${agotada ? 'text-red-600' : disponible <= 5 ? 'text-amber-600' : 'text-green-700'}`}>
              {agotada ? 'Agotado' : disponible <= 5 ? `Quedan ${disponible} unidades` : 'Disponible'}
              <span className="ml-2 text-gray-400">SKU {variante.sku}</span>
            </p>
          )}

          <div className="mt-6 flex items-end gap-3">
            <div>
              <label htmlFor="cantidad" className="mb-1 block text-sm font-medium text-gray-700">
                Cantidad
              </label>
              <input
                id="cantidad"
                type="number"
                min={1}
                max={Math.max(1, disponible)}
                value={cantidad}
                disabled={agotada}
                onChange={(e) => cambiarCantidad(Number(e.target.value))}
                className="w-24 rounded-md border border-gray-300 px-3 py-2 text-sm disabled:bg-gray-100"
              />
            </div>
            {puedeComprar && (
              <Boton onClick={agregarAlCarrito} disabled={agotada} cargando={agregar.isPending}>
                Agregar al carrito
              </Boton>
            )}
          </div>
          {!puedeComprar && (
            <p className='mt-4 text-sm text-gray-500'>
              Las cuentas de gestión no realizan compras.
            </p>
          )}

          {aviso&&(
            <p role='status' className='mt-3 text-sm text-green-700'>
              {aviso}{' '}
              <Link to='/carrito' className='font-medium underline'>
              Ver carrito
              </Link>
            </p>
          )}

          {agregar.isError && (
            <p role='alert' className='mt-3 text-sm text-red-600'>
              {normalizarError(agregar.error).mensaje}
            </p>
          )}
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
      <main className="mx-auto max-w-7xl p-6">
        <EstadoError error={new Error('El producto solicitado no es válido.')} />
      </main>
    );
  }

  if (consulta.isPending) return <EstadoCarga mensaje="Cargando producto..." />;

  if (consulta.isError) {
    return (
      <main className="mx-auto max-w-7xl p-6">
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
        <p className="text-center">
          <Link to="/catalogo" className="text-sm text-indigo-600 hover:underline">
            Volver al catálogo
          </Link>
        </p>
      </main>
    );
  }

  return <DetalleProducto key={consulta.data.producto.idProducto} detalle={consulta.data} />;
}