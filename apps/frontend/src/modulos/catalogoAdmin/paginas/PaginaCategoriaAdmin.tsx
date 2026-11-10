import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { DialogoConfirmacion } from '../../../componentes/DialogoConfirmacion';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearFecha } from '../../../utilidades/formato';
import { DialogoCategoria } from '../componentes/DialogoCategoria';
import { useAccionesCategoria, useCategoriasAdmin } from '../hooks/useCatalogoAdmin';
import type { CategoriaAdmin, FiltrosCategoriasAdmin } from '../tipos/catalogoAdmin';

const OPCIONES_ORDEN = [
  { valor: 'Nombre|ASC', etiqueta: 'Nombre (A-Z)' },
  { valor: 'Nombre|DESC', etiqueta: 'Nombre (Z-A)' },
  { valor: 'FechaCreacion|DESC', etiqueta: 'Más recientes' },
  { valor: 'FechaCreacion|ASC', etiqueta: 'Más antiguas' },
] as const;

const claseSelect =
  'control';

interface AccionCategoria {
  tipo: 'activar' | 'desactivar' | 'eliminar';
  categoria: CategoriaAdmin;
}

interface PropiedadesFiltros {
  busqueda: string;
  activo: string;
  orden: string;
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

function Filtros({ busqueda, activo, orden, alCambiar, alLimpiar }: PropiedadesFiltros) {
  const [texto, setTexto] = useState(busqueda);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    alCambiar({ busqueda: texto.trim() || undefined });
  };

  return (
    <form onSubmit={aplicar} noValidate className="tarjeta grid gap-4 p-4 sm:grid-cols-2 lg:grid-cols-5 lg:items-end">
      <div className="lg:col-span-2">
        <CampoFormulario etiqueta="Buscar" type="search" maxLength={100} value={texto} onChange={(e) => setTexto(e.target.value)} />
      </div>

      <div>
        <label htmlFor="cat-estado" className="mb-1.5 block text-sm font-medium text-gray-700">
          Estado
        </label>
        <select id="cat-estado" className={claseSelect} value={activo} onChange={(e) => alCambiar({ activo: e.target.value || undefined })}>
          <option value="">Todas</option>
          <option value="true">Activas</option>
          <option value="false">Inactivas</option>
        </select>
      </div>

      <div>
        <label htmlFor="cat-orden" className="mb-1.5 block text-sm font-medium text-gray-700">
          Ordenar por
        </label>
        <select id="cat-orden" className={claseSelect} value={orden} onChange={(e) => alCambiar({ orden: e.target.value })}>
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
            setTexto('');
            alLimpiar();
          }}
        >
          Limpiar
        </Boton>
      </div>
    </form>
  );
}

export function PaginaCategoriasAdmin() {
  const { params, actualizar, limpiar } = useParametrosUrl();

  const busqueda = params.get('busqueda') ?? '';
  const activoParam = params.get('activo') ?? '';
  const activo = activoParam === 'true' ? true : activoParam === 'false' ? false : undefined;
  const orden = OPCIONES_ORDEN.find((o) => o.valor === params.get('orden'))?.valor ?? 'Nombre|ASC';
  const [ordenarPor, direccion] = orden.split('|') as [FiltrosCategoriasAdmin['ordenarPor'], FiltrosCategoriasAdmin['direccion']];
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useCategoriasAdmin({
    busqueda: busqueda || undefined,
    activo,
    ordenarPor,
    direccion,
    pagina,
    registrosPorPagina: 20,
  });
  const acciones = useAccionesCategoria();

  const [dialogoCategoria, setDialogoCategoria] = useState<{ categoria: CategoriaAdmin | null } | null>(null);
  const [accion, setAccion] = useState<AccionCategoria | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);

  const abrirAccion = (nueva: AccionCategoria) => {
    acciones.eliminar.reset();
    acciones.cambiarEstado.reset();
    setAccion(nueva);
  };

  const confirmar = () => {
    if (!accion) return;
    const { tipo, categoria } = accion;
    const alExito = (mensaje: string) => () => {
      setAviso(mensaje);
      setAccion(null);
    };

    if (tipo === 'eliminar') {
      acciones.eliminar.mutate(categoria.idCategoria, { onSuccess: alExito(`Categoría «${categoria.nombre}» eliminada.`) });
    } else {
      acciones.cambiarEstado.mutate(
        { idCategoria: categoria.idCategoria, activo: tipo === 'activar' },
        { onSuccess: alExito(`Categoría «${categoria.nombre}» ${tipo === 'activar' ? 'activada' : 'desactivada'}.`) }
      );
    }
  };

  const mutacionActual = accion?.tipo === 'eliminar' ? acciones.eliminar : acciones.cambiarEstado;
  const textosAccion = accion && {
    activar: { titulo: 'Activar categoría', mensaje: `«${accion.categoria.nombre}» volverá a mostrarse en la tienda.`, boton: 'Activar' },
    desactivar: { titulo: 'Desactivar categoría', mensaje: `Al desactivar «${accion.categoria.nombre}», sus productos dejarán de mostrarse en la tienda.`, boton: 'Desactivar' },
    eliminar: { titulo: 'Eliminar categoría', mensaje: `Se eliminará «${accion.categoria.nombre}». Si tiene productos asociados no se podrá eliminar; en ese caso puedes desactivarla.`, boton: 'Eliminar' },
  }[accion.tipo];

  const claseBotonFila = 'boton-fila';

  return (
    <main className="mx-auto max-w-7xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold tracking-tight sm:text-3xl">Categorías</h1>
        <Boton onClick={() => setDialogoCategoria({ categoria: null })}>Nueva categoría</Boton>
      </div>

      {aviso && (
        <p role="status" className="flex items-center justify-between gap-3 rounded-control border border-green-200 bg-green-50 p-3 text-sm text-green-800">
          {aviso}
          <button type="button" onClick={() => setAviso(null)} className="min-h-9 shrink-0 font-medium underline underline-offset-2">
            Cerrar
          </button>
        </p>
      )}

      <Filtros key={busqueda} busqueda={busqueda} activo={activoParam} orden={orden} alCambiar={actualizar} alLimpiar={limpiar} />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando categorías..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.categorias.length === 0 ? (
        <EstadoVacio titulo="No hay categorías" descripcion="Prueba con otros filtros o crea una nueva." />
      ) : (
        <>
          <p className="text-sm text-gray-600">{consulta.data.totalRegistros} categorías</p>

          <div className={`tarjeta overflow-x-auto transition-opacity duration-150 ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="tabla">
              <thead>
                <tr>
                  <th className="px-4 py-3">Nombre</th>
                  <th className="px-4 py-3">Descripción</th>
                  <th className="px-4 py-3 text-right">Productos</th>
                  <th className="px-4 py-3">Estado</th>
                  <th className="px-4 py-3">Creada</th>
                  <th className="px-4 py-3">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.categorias.map((c) => (
                  <tr key={c.idCategoria}>
                    <td className="px-4 py-3 font-medium">{c.nombre}</td>
                    <td className="max-w-xs px-4 py-3 text-gray-600">{c.descripcion ?? '—'}</td>
                    <td className="px-4 py-3 text-right">{c.totalProductos}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${c.activo ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'}`}>
                        {c.activo ? 'Activa' : 'Inactiva'}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-4 py-3">{formatearFecha(c.fechaCreacion)}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        <button type="button" className={claseBotonFila} onClick={() => setDialogoCategoria({ categoria: c })}>
                          Editar
                        </button>
                        <button type="button" className={claseBotonFila} onClick={() => abrirAccion({ tipo: c.activo ? 'desactivar' : 'activar', categoria: c })}>
                          {c.activo ? 'Desactivar' : 'Activar'}
                        </button>
                        <button type="button" className={`${claseBotonFila} text-red-600`} onClick={() => abrirAccion({ tipo: 'eliminar', categoria: c })}>
                          Eliminar
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

      <DialogoCategoria
        abierto={dialogoCategoria !== null}
        categoria={dialogoCategoria?.categoria ?? null}
        alCerrar={() => setDialogoCategoria(null)}
        alGuardada={setAviso}
      />

      <DialogoConfirmacion
        abierto={accion !== null}
        titulo={textosAccion?.titulo ?? ''}
        mensaje={textosAccion?.mensaje ?? ''}
        textoConfirmar={textosAccion?.boton ?? ''}
        peligro={accion?.tipo !== 'activar'}
        cargando={mutacionActual.isPending}
        error={mutacionActual.isError ? normalizarError(mutacionActual.error).mensaje : null}
        alConfirmar={confirmar}
        alCerrar={() => setAccion(null)}
      />
    </main>
  );
}