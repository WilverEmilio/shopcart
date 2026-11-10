import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Boton } from '../../../componentes/Boton';
import { Paginador } from '../../../componentes/Paginador';
import { PanelFiltros } from '../componentes/PanelFiltros';
import { TarjetaProducto, TarjetaProductoEsqueleto } from '../componentes/TarjetaProducto';
import { useCategoriasPublicas, useProductos } from '../hooks/useCatalogo';
import { useFiltrosCatalogo } from '../hooks/useFiltrosCatalogo';

const GARANTIAS = [
  { texto: 'Envíos a los 22 departamentos', icono: 'M3 7h11v9H3zM14 10h4l3 3v3h-7M7 19a2 2 0 1 0 0-.01M17 19a2 2 0 1 0 0-.01' },
  { texto: 'Pago seguro', icono: 'M6 11V8a6 6 0 0 1 12 0v3M5 11h14v10H5zM12 15v2' },
  { texto: 'Devoluciones', icono: 'M4 9h11a5 5 0 0 1 0 10H8M4 9l4-4M4 9l4 4' },
] as const;

const claseRejilla ='grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3';

export function PaginaCatalogo() {
  const { filtros, actualizar, limpiar } = useFiltrosCatalogo();
  const consulta = useProductos(filtros);
  const categorias = useCategoriasPublicas();

  const clavePanel = `${filtros.texto ?? ''}|${filtros.precioMinimo ?? ''}|${filtros.precioMaximo ?? ''}`;

  const cambiarPagina = (pagina: number) => {
    actualizar({ pagina: String(pagina) });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <main className="mx-auto max-w-7xl px-4 py-6 sm:px-6 sm:py-8">
      <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <h1 className="text-3xl font-bold sm:text-4xl">Catálogo</h1>
          <p className="mt-1 text-slate-600">Ropa, calzado, electrónica, hogar y más. Precios en quetzales con IVA incluido.</p>
        </div>

        <ul aria-label="Por qué comprar en ShopCart" className="grid gap-2 text-sm text-slate-700 sm:grid-cols-3 lg:flex lg:gap-5">
          {GARANTIAS.map((g) => (
            <li key={g.texto} className="flex items-center gap-2">
              <span aria-hidden="true" className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-marca-50 text-marca-700">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
                  <path strokeLinecap="round" strokeLinejoin="round" d={g.icono} />
                </svg>
              </span>
              {g.texto}
            </li>
          ))}
        </ul>
      </div>

      <div className="grid gap-6 lg:grid-cols-[16rem_1fr] lg:gap-8">
        <PanelFiltros
          key={clavePanel}
          filtros={filtros}
          categorias={categorias.data ?? []}
          alCambiar={actualizar}
          alLimpiar={limpiar}
        />

        <section aria-live="polite" aria-busy={consulta.isPending || consulta.isPlaceholderData}>
          {consulta.isPending ? (
            <div role="status">
              <span className="sr-only">Cargando productos...</span>
              <div className="mb-4 h-5" />
              <div className={claseRejilla}>
                {Array.from({ length: 6 }, (_, i) => (
                  <TarjetaProductoEsqueleto key={i} />
                ))}
              </div>
            </div>
          ) : consulta.isError ? (
            <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
          ) : consulta.data.productos.length === 0 ? (
            <div className="tarjeta">
              <EstadoVacio
                titulo="No encontramos productos"
                descripcion="Prueba con otros filtros o limpia la búsqueda."
                accion={
                  <Boton variante="secundario" onClick={limpiar}>
                    Limpiar filtros
                  </Boton>
                }
              />
            </div>
          ) : (
            <>
              <p className="mb-4 h-5 text-sm text-slate-600">
                {consulta.data.totalRegistros} {consulta.data.totalRegistros === 1 ? 'producto' : 'productos'}
              </p>

              <div
                className={`${claseRejilla} transition-opacity duration-150 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}
              >
                {consulta.data.productos.map((p) => (
                  <TarjetaProducto key={p.idProducto} producto={p} />
                ))}
              </div>

              <Paginador
                pagina={consulta.data.pagina}
                tamanoPagina={consulta.data.tamanoPagina}
                totalRegistros={consulta.data.totalRegistros}
                alCambiar={cambiarPagina}
              />
            </>
          )}
        </section>
      </div>
    </main>
  );
}
