import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { PanelFiltros } from '../componentes/PanelFiltros';
import { TarjetaProducto } from '../componentes/TarjetaProducto';
import { useCategoriasPublicas, useProductos } from '../hooks/useCatalogo';
import { useFiltrosCatalogo } from '../hooks/useFiltrosCatalogo';

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
    <main className="mx-auto max-w-7xl p-6">
      <h1 className="mb-6 text-2xl font-semibold">Catálogo</h1>

      <div className="grid gap-6 lg:grid-cols-[16rem_1fr]">
        <PanelFiltros
          key={clavePanel}
          filtros={filtros}
          categorias={categorias.data ?? []}
          alCambiar={actualizar}
          alLimpiar={limpiar}
        />

        <section aria-live="polite">
          {consulta.isPending ? (
            <EstadoCarga mensaje="Cargando productos..." />
          ) : consulta.isError ? (
            <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
          ) : consulta.data.productos.length === 0 ? (
            <EstadoVacio
              titulo="No encontramos productos"
              descripcion="Prueba con otros filtros o limpia la búsqueda."
            />
          ) : (
            <>
              <p className="mb-4 text-sm text-gray-500">
                {consulta.data.totalRegistros} {consulta.data.totalRegistros === 1 ? 'producto' : 'productos'}
              </p>

              <div
                className={`grid gap-4 sm:grid-cols-2 xl:grid-cols-3 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}
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