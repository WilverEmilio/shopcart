import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Boton } from '../../../componentes/Boton';
import { Paginador } from '../../../componentes/Paginador';
import { PanelFiltros } from '../componentes/PanelFiltros';
import { TarjetaProducto, TarjetaProductoEsqueleto } from '../componentes/TarjetaProducto';
import { useCategoriasPublicas, useProductos } from '../hooks/useCatalogo';
import { useFiltrosCatalogo } from '../hooks/useFiltrosCatalogo';

const claseRejilla = 'grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3';

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
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Catálogo</h1>
        <p className="mt-1 text-sm text-gray-600">Precios en quetzales con IVA incluido.</p>
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
              <p className="mb-4 h-5 text-sm text-gray-600">
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
