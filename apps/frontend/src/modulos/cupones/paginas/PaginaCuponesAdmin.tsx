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
import { formatearFechaHora, formatearMoneda } from '../../../utilidades/formato';
import { useCategoriasAdmin } from '../../catalogoAdmin/hooks/useCatalogoAdmin';
import type { CategoriaAdmin, FiltrosCategoriasAdmin } from '../../catalogoAdmin/tipos/catalogoAdmin';
import { DialogoCupon } from '../componentes/DialogoCupon';
import { CLASE_ESTADO_CUPON, ESTADOS_CUPON, ETIQUETA_ESTADO_CUPON } from '../constantes';
import { useAccionesCupon, useCupones } from '../hooks/useCupones';
import type { Cupon, FiltrosCupones } from '../tipos/cupon';

const OPCIONES_ORDEN = [
  { valor: 'FechaFin|DESC', etiqueta: 'Vencen más tarde' },
  { valor: 'FechaFin|ASC', etiqueta: 'Vencen primero' },
  { valor: 'UsosActuales|DESC', etiqueta: 'Más usados' },
  { valor: 'Codigo|ASC', etiqueta: 'Código (A-Z)' },
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
const claseBotonFila = 'rounded-md border border-gray-300 px-2 py-1 text-xs font-medium hover:bg-gray-100';

interface AccionCupon {
  tipo: 'activar' | 'desactivar' | 'eliminar';
  cupon: Cupon;
}

interface PropiedadesFiltros {
  busqueda: string;
  estado: string;
  idCategoria: number | undefined;
  orden: string;
  categorias: CategoriaAdmin[];
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

function Filtros({ busqueda, estado, idCategoria, orden, categorias, alCambiar, alLimpiar }: PropiedadesFiltros) {
  const [texto, setTexto] = useState(busqueda);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    alCambiar({ busqueda: texto.trim() || undefined });
  };

  return (
    <form onSubmit={aplicar} noValidate className="grid gap-4 rounded-lg border border-gray-200 bg-white p-4 sm:grid-cols-2 lg:grid-cols-5 lg:items-end">
      <CampoFormulario etiqueta="Buscar" type="search" placeholder="Código o descripción" maxLength={100} value={texto} onChange={(e) => setTexto(e.target.value)} />

      <div>
        <label htmlFor="cup-estado" className="mb-1 block text-sm font-medium text-gray-700">
          Estado
        </label>
        <select id="cup-estado" className={claseSelect} value={estado} onChange={(e) => alCambiar({ estado: e.target.value || undefined })}>
          <option value="">Todos</option>
          {ESTADOS_CUPON.map((e) => (
            <option key={e} value={e}>
              {ETIQUETA_ESTADO_CUPON[e]}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="cup-categoria" className="mb-1 block text-sm font-medium text-gray-700">
          Categoría
        </label>
        <select id="cup-categoria" className={claseSelect} value={idCategoria ?? ''} onChange={(e) => alCambiar({ categoria: e.target.value || undefined })}>
          <option value="">Todas</option>
          {categorias.map((c) => (
            <option key={c.idCategoria} value={c.idCategoria}>
              {c.nombre}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label htmlFor="cup-orden" className="mb-1 block text-sm font-medium text-gray-700">
          Ordenar por
        </label>
        <select id="cup-orden" className={claseSelect} value={orden} onChange={(e) => alCambiar({ orden: e.target.value })}>
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

export function PaginaCuponesAdmin() {
  const { params, actualizar, limpiar } = useParametrosUrl();
  const categorias = useCategoriasAdmin(TODAS_LAS_CATEGORIAS);
  const acciones = useAccionesCupon();

  const busqueda = params.get('busqueda') ?? '';
  const estadoParam = params.get('estado') ?? '';
  const estado = ESTADOS_CUPON.find((e) => e === estadoParam);
  const idCategoria = Number(params.get('categoria')) || undefined;
  const orden = OPCIONES_ORDEN.find((o) => o.valor === params.get('orden'))?.valor ?? 'FechaFin|DESC';
  const [ordenarPor, direccion] = orden.split('|') as [FiltrosCupones['ordenarPor'], FiltrosCupones['direccion']];
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useCupones({
    busqueda: busqueda || undefined,
    estado,
    idCategoria,
    ordenarPor,
    direccion,
    pagina,
    registrosPorPagina: 20,
  });

  const [dialogoCupon, setDialogoCupon] = useState<{ cupon: Cupon | null } | null>(null);
  const [accion, setAccion] = useState<AccionCupon | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);

  const abrirAccion = (nueva: AccionCupon) => {
    acciones.eliminar.reset();
    acciones.cambiarEstado.reset();
    setAccion(nueva);
  };

  const confirmar = () => {
    if (!accion) return;
    const { tipo, cupon } = accion;
    const alExito = (mensaje: string) => () => {
      setAviso(mensaje);
      setAccion(null);
    };

    if (tipo === 'eliminar') {
      acciones.eliminar.mutate(cupon.idCupon, { onSuccess: alExito(`Cupón ${cupon.codigo} eliminado.`) });
    } else {
      acciones.cambiarEstado.mutate(
        { idCupon: cupon.idCupon, activo: tipo === 'activar' },
        { onSuccess: alExito(`Cupón ${cupon.codigo} ${tipo === 'activar' ? 'activado' : 'desactivado'}.`) }
      );
    }
  };

  const mutacionActual = accion?.tipo === 'eliminar' ? acciones.eliminar : acciones.cambiarEstado;
  const textosAccion = accion && {
    activar: { titulo: 'Activar cupón', mensaje: `El cupón ${accion.cupon.codigo} podrá usarse de nuevo (si está dentro de su vigencia).`, boton: 'Activar' },
    desactivar: { titulo: 'Desactivar cupón', mensaje: `El cupón ${accion.cupon.codigo} dejará de aceptarse en el carrito. Los pedidos ya hechos no cambian.`, boton: 'Desactivar' },
    eliminar: { titulo: 'Eliminar cupón', mensaje: `Se eliminará el cupón ${accion.cupon.codigo}. Si ya fue utilizado no se podrá eliminar; en ese caso desactívalo.`, boton: 'Eliminar' },
  }[accion.tipo];

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Cupones</h1>
        <Boton onClick={() => setDialogoCupon({ cupon: null })}>Nuevo cupón</Boton>
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
        key={busqueda}
        busqueda={busqueda}
        estado={estadoParam}
        idCategoria={idCategoria}
        orden={orden}
        categorias={categorias.data?.categorias ?? []}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando cupones..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="No hay cupones" descripcion="Prueba con otros filtros o crea uno nuevo." />
      ) : (
        <>
          <p className="text-sm text-gray-500">{consulta.data.totalRegistros} cupones</p>

          <div className={`overflow-x-auto rounded-lg border border-gray-200 bg-white ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">Código</th>
                  <th className="px-4 py-3">Descuento</th>
                  <th className="px-4 py-3">Aplica a</th>
                  <th className="px-4 py-3 text-right">Mínimo</th>
                  <th className="px-4 py-3">Vigencia</th>
                  <th className="px-4 py-3">Usos</th>
                  <th className="px-4 py-3">Estado</th>
                  <th className="px-4 py-3">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((c) => (
                  <tr key={c.idCupon} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <p className="font-mono font-semibold">{c.codigo}</p>
                      {c.descripcion && <p className="max-w-[14rem] text-xs text-gray-500">{c.descripcion}</p>}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3">
                      {c.tipoDescuento === 'PORCENTAJE' ? `${c.valor} %` : formatearMoneda(c.valor)}
                    </td>
                    <td className="px-4 py-3 text-gray-600">{c.categoria ?? 'Todo el carrito'}</td>
                    <td className="whitespace-nowrap px-4 py-3 text-right">{c.montoMinimo > 0 ? formatearMoneda(c.montoMinimo) : '—'}</td>
                    <td className="whitespace-nowrap px-4 py-3 text-xs text-gray-600">
                      <p>{formatearFechaHora(c.fechaInicio)}</p>
                      <p>{formatearFechaHora(c.fechaFin)}</p>
                    </td>
                    <td className="px-4 py-3 text-xs">
                      <p>
                        {c.usosActuales} / {c.limiteUsosTotal ?? '∞'}
                      </p>
                      <p className="text-gray-500">{c.limiteUsosPorCliente ? `${c.limiteUsosPorCliente} por cliente` : 'sin límite por cliente'}</p>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${CLASE_ESTADO_CUPON[c.estado]}`}>
                        {ETIQUETA_ESTADO_CUPON[c.estado]}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        <button type="button" className={claseBotonFila} onClick={() => setDialogoCupon({ cupon: c })}>
                          Editar
                        </button>
                        <button type="button" className={claseBotonFila} onClick={() => abrirAccion({ tipo: c.activo ? 'desactivar' : 'activar', cupon: c })}>
                          {c.activo ? 'Desactivar' : 'Activar'}
                        </button>
                        <button type="button" className={`${claseBotonFila} text-red-600`} onClick={() => abrirAccion({ tipo: 'eliminar', cupon: c })}>
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

      <DialogoCupon
        abierto={dialogoCupon !== null}
        cupon={dialogoCupon?.cupon ?? null}
        alCerrar={() => setDialogoCupon(null)}
        alGuardado={setAviso}
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