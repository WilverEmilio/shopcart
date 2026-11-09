import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { DialogoConfirmacion } from '../../../componentes/DialogoConfirmacion';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda } from '../../../utilidades/formato';
import { useProductos } from '../../catalogo/hooks/useCatalogo';
import type { DireccionOrden, OrdenCatalogo, ProductoCatalogo } from '../../catalogo/tipos/catalogo';
import { useAccionesProducto, useCategoriasAdmin } from '../hooks/useCatalogoAdmin';
import type { CategoriaAdmin, FiltrosCategoriasAdmin } from '../tipos/catalogoAdmin';

const OPCIONES_ORDEN = [
  { valor: 'Nombre|ASC', etiqueta: 'Nombre (A-Z)' },
  { valor: 'Nombre|DESC', etiqueta: 'Nombre (Z-A)' },
  { valor: 'Precio|ASC', etiqueta: 'Precio: menor a mayor' },
  { valor: 'Precio|DESC', etiqueta: 'Precio: mayor a menor' },
  { valor: 'FechaCreacion|DESC', etiqueta: 'Más recientes' },
] as const;

const TODAS_LAS_CATEGORIAS: FiltrosCategoriasAdmin = {
  ordenarPor: 'Nombre',
  direccion: 'ASC',
  pagina: 1,
  registrosPorPagina: 100,
};

const claseSelect =
  'w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500';

interface PropiedadesFiltros {
  texto: string;
  idCategoria: number | undefined;
  activo: string;
  orden: string;
  categorias: CategoriaAdmin[];
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

function Filtros({ texto, idCategoria, activo, orden, categorias, alCambiar, alLimpiar }: PropiedadesFiltros) {
  const [textoLocal, setTextoLocal] = useState(texto);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    alCambiar({ texto: textoLocal.trim() || undefined });
  };

  return (
    <form onSubmit={aplicar} noValidate className="grid gap-4 rounded-lg border border-gray-200 bg-white p-4 sm:grid-cols-2 lg:grid-cols-5 lg:items-end">
      <CampoFormulario etiqueta="Buscar" type="search" placeholder="Nombre, descripción o SKU" maxLength={100} value={textoLocal} onChange={(e) => setTextoLocal(e.target.value)} />

      <div>
        <label htmlFor="prod-categoria" className="mb-1 block text-sm font-medium text-gray-700">
          Categoría
        </label>
        <select id="prod-categoria" className={claseSelect} value={idCategoria ?? ''} onChange={(e) => alCambiar({ categoria: e.target.value || undefined })}>
          <option value="">Todas</option>
          {categorias.map((c) => (
            <option key={c.idCategoria} value={c.idCategoria}>
              {c.nombre}
              {c.activo ? '' : ' (inactiva)'}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="prod-estado" className="mb-1 block text-sm font-medium text-gray-700">
          Estado
        </label>
        <select id="prod-estado" className={claseSelect} value={activo} onChange={(e) => alCambiar({ activo: e.target.value || undefined })}>
          <option value="">Todos</option>
          <option value="true">Activos</option>
          <option value="false">Inactivos</option>
        </select>
      </div>

      <div>
        <label htmlFor="prod-orden" className="mb-1 block text-sm font-medium text-gray-700">
          Ordenar por
        </label>
        <select id="prod-orden" className={claseSelect} value={orden} onChange={(e) => alCambiar({ orden: e.target.value })}>
          {OPCIONES_ORDEN.map((o) => (
            <option key={o.valor} value={o.valor}>
              {o.etiqueta}
            </option>
          ))}
        </select>
      </div>

      <div className="flex gap-2">
        <Boton type="submit">Aplicar</Boton>
        <Boton
          variante="secundario"
          onClick={() => {
            setTextoLocal('');
            alLimpiar();
          }}
        >
          Limpiar
        </Boton>
      </div>
    </form>
  );
}

export function PaginaProductosAdmin() {
  const { params, actualizar, limpiar } = useParametrosUrl();
  const categorias = useCategoriasAdmin(TODAS_LAS_CATEGORIAS);
  const acciones = useAccionesProducto();

  const texto = params.get('texto') ?? '';
  const idCategoria = Number(params.get('categoria')) || undefined;
  const activoParam = params.get('activo') ?? '';
  const activo = activoParam === 'true' ? true : activoParam === 'false' ? false : undefined;
  const orden = OPCIONES_ORDEN.find((o) => o.valor === params.get('orden'))?.valor ?? 'Nombre|ASC';
  const [ordenarPor, direccion] = orden.split('|') as [OrdenCatalogo, DireccionOrden];
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useProductos({
    texto: texto || undefined,
    idCategoria,
    activo,
    ordenarPor,
    direccion,
    pagina,
    registrosPorPagina: 20,
  });

  const [productoAccion, setProductoAccion] = useState<ProductoCatalogo | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);

  const confirmar = () => {
    if (!productoAccion) return;
    const nuevoEstado = !productoAccion.activo;
    acciones.cambiarEstado.mutate(
      { idProducto: productoAccion.idProducto, activo: nuevoEstado },
      {
        onSuccess: () => {
          setAviso(`Producto «${productoAccion.nombre}» ${nuevoEstado ? 'activado' : 'desactivado'}.`);
          setProductoAccion(null);
        },
      }
    );
  };

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Productos</h1>
        <Link to="/admin/productos/nuevo" className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700">
          Nuevo producto
        </Link>
      </div>

      {aviso && (
        <p role="status" className="flex items-center justify-between rounded-md bg-green-50 p-3 text-sm text-green-800">
          {aviso}
          <button type="button" onClick={() => setAviso(null)} className="underline">
            Cerrar
          </button>
        </p>
      )}

      <Filtros
        key={texto}
        texto={texto}
        idCategoria={idCategoria}
        activo={activoParam}
        orden={orden}
        categorias={categorias.data?.categorias ?? []}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando productos..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.productos.length === 0 ? (
        <EstadoVacio titulo="No hay productos" descripcion="Prueba con otros filtros o crea uno nuevo." />
      ) : (
        <>
          <p className="text-sm text-gray-500">{consulta.data.totalRegistros} productos</p>

          <div className={`overflow-x-auto rounded-lg border border-gray-200 bg-white ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">Producto</th>
                  <th className="px-4 py-3">Categoría</th>
                  <th className="px-4 py-3 text-right">Precio</th>
                  <th className="px-4 py-3 text-right">Variantes</th>
                  <th className="px-4 py-3 text-right">Disponible</th>
                  <th className="px-4 py-3">Estado</th>
                  <th className="px-4 py-3">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.productos.map((p) => (
                  <tr key={p.idProducto} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <ImagenProducto url={p.imagenPrincipal} alt={p.nombre} className="h-12 w-12 shrink-0 rounded-md border border-gray-200 object-cover" />
                        <span className="font-medium">{p.nombre}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">{p.categoria}</td>
                    <td className="whitespace-nowrap px-4 py-3 text-right">
                      {p.precioDesde === p.precioHasta
                        ? formatearMoneda(p.precioDesde)
                        : `${formatearMoneda(p.precioDesde)} – ${formatearMoneda(p.precioHasta)}`}
                    </td>
                    <td className="px-4 py-3 text-right">{p.totalVariantes}</td>
                    <td className={`px-4 py-3 text-right ${p.disponible <= 0 ? 'font-semibold text-red-600' : ''}`}>{p.disponible}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${p.activo ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'}`}>
                        {p.activo ? 'Activo' : 'Inactivo'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        <Link to={`/admin/productos/${p.idProducto}`} className="rounded-md border border-gray-300 px-2 py-1 text-xs font-medium hover:bg-gray-100">
                          Editar
                        </Link>
                        <button
                          type="button"
                          className="rounded-md border border-gray-300 px-2 py-1 text-xs font-medium hover:bg-gray-100"
                          onClick={() => {
                            acciones.cambiarEstado.reset();
                            setProductoAccion(p);
                          }}
                        >
                          {p.activo ? 'Desactivar' : 'Activar'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Paginador
            pagina={consulta.data.pagina}
            tamanoPagina={consulta.data.tamanoPagina}
            totalRegistros={consulta.data.totalRegistros}
            alCambiar={(p) => actualizar({ pagina: String(p) })}
          />
        </>
      )}

      <DialogoConfirmacion
        abierto={productoAccion !== null}
        titulo={productoAccion?.activo ? 'Desactivar producto' : 'Activar producto'}
        mensaje={
          productoAccion?.activo
            ? `«${productoAccion.nombre}» dejará de mostrarse en la tienda. Los pedidos existentes no se ven afectados.`
            : `«${productoAccion?.nombre ?? ''}» volverá a mostrarse en la tienda.`
        }
        textoConfirmar={productoAccion?.activo ? 'Desactivar' : 'Activar'}
        peligro={productoAccion?.activo ?? false}
        cargando={acciones.cambiarEstado.isPending}
        error={acciones.cambiarEstado.isError ? normalizarError(acciones.cambiarEstado.error).mensaje : null}
        alConfirmar={confirmar}
        alCerrar={() => setProductoAccion(null)}
      />
    </main>
  );
}