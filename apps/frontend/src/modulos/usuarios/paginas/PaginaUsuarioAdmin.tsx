import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { DialogoConfirmacion } from '../../../componentes/DialogoConfirmacion';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { EstadoVacio } from '../../../componentes/EstadoVacio';
import { Paginador } from '../../../componentes/Paginador';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { useParametrosUrl } from '../../../hooks/useParametrosUrl';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearFecha } from '../../../utilidades/formato';
import { DialogoUsuario } from '../componentes/DialogoUsuario';
import { useAccionesUsuario, useRoles, useUsuarios } from '../hooks/useUsuarios';
import type { FiltrosUsuarios, RolSistema, UsuarioAdmin } from '../tipos/usuarioAdmin';

const OPCIONES_ORDEN = [
  { valor: 'FechaCreacion|DESC', etiqueta: 'Más recientes' },
  { valor: 'FechaCreacion|ASC', etiqueta: 'Más antiguos' },
  { valor: 'Nombres|ASC', etiqueta: 'Nombre (A-Z)' },
  { valor: 'Correo|ASC', etiqueta: 'Correo (A-Z)' },
] as const;

const CLASE_ROL: Record<string, string> = {
  Administrador: 'bg-indigo-100 text-indigo-800',
  Operador: 'bg-blue-100 text-blue-800',
  Cliente: 'bg-gray-200 text-gray-700',
};

const claseSelect =
  'w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500';

interface AccionUsuario {
  tipo: 'activar' | 'desactivar';
  usuario: UsuarioAdmin;
}

interface PropiedadesFiltros {
  busqueda: string;
  idRol: number | undefined;
  activo: string;
  orden: string;
  roles: RolSistema[];
  alCambiar: (cambios: Record<string, string | undefined>) => void;
  alLimpiar: () => void;
}

function Filtros({ busqueda, idRol, activo, orden, roles, alCambiar, alLimpiar }: PropiedadesFiltros) {
  const [texto, setTexto] = useState(busqueda);

  const aplicar = (evento: FormEvent) => {
    evento.preventDefault();
    alCambiar({ busqueda: texto.trim() || undefined });
  };

  return (
    <form onSubmit={aplicar} noValidate className="grid gap-4 rounded-lg border border-gray-200 bg-white p-4 sm:grid-cols-2 lg:grid-cols-5 lg:items-end">
      <CampoFormulario etiqueta="Buscar" type="search" placeholder="Nombre o correo" maxLength={100} value={texto} onChange={(e) => setTexto(e.target.value)} />

      {roles.length > 0 ? (
        <div>
          <label htmlFor="usr-rol" className="mb-1 block text-sm font-medium text-gray-700">
            Rol
          </label>
          <select id="usr-rol" className={claseSelect} value={idRol ?? ''} onChange={(e) => alCambiar({ rol: e.target.value || undefined })}>
            <option value="">Todos</option>
            {roles.map((r) => (
              <option key={r.idRol} value={r.idRol}>
                {r.nombres}
              </option>
            ))}
          </select>
        </div>
      ) : (
        <div />
      )}

      <div>
        <label htmlFor="usr-estado" className="mb-1 block text-sm font-medium text-gray-700">
          Estado
        </label>
        <select id="usr-estado" className={claseSelect} value={activo} onChange={(e) => alCambiar({ activo: e.target.value || undefined })}>
          <option value="">Todos</option>
          <option value="true">Activos</option>
          <option value="false">Inactivos</option>
        </select>
      </div>

      <div>
        <label htmlFor="usr-orden" className="mb-1 block text-sm font-medium text-gray-700">
          Ordenar por
        </label>
        <select id="usr-orden" className={claseSelect} value={orden} onChange={(e) => alCambiar({ orden: e.target.value })}>
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

export function PaginaUsuariosAdmin() {
  const { params, actualizar, limpiar } = useParametrosUrl();
  const miId = useSesionEstado((e) => e.usuario?.idUsuario);
  const roles = useRoles();
  const acciones = useAccionesUsuario();

  const busqueda = params.get('busqueda') ?? '';
  const idRol = Number(params.get('rol')) || undefined;
  const activoParam = params.get('activo') ?? '';
  const activo = activoParam === 'true' ? true : activoParam === 'false' ? false : undefined;
  const orden = OPCIONES_ORDEN.find((o) => o.valor === params.get('orden'))?.valor ?? 'FechaCreacion|DESC';
  const [ordenarPor, direccion] = orden.split('|') as [FiltrosUsuarios['ordenarPor'], FiltrosUsuarios['direccion']];
  const pagina = Math.max(1, Math.trunc(Number(params.get('pagina'))) || 1);

  const consulta = useUsuarios({
    busqueda: busqueda || undefined,
    idRol,
    activo,
    ordenarPor,
    direccion,
    pagina,
    registroPorPagina: 20,
  });

  const [dialogoNuevo, setDialogoNuevo] = useState(false);
  const [accion, setAccion] = useState<AccionUsuario | null>(null);
  const [aviso, setAviso] = useState<string | null>(null);

  const confirmar = () => {
    if (!accion) return;
    const { tipo, usuario } = accion;
    acciones.cambiarEstado.mutate(
      { idUsuario: usuario.idUsuario, activo: tipo === 'activar' },
      {
        onSuccess: () => {
          setAviso(`Usuario ${usuario.correo} ${tipo === 'activar' ? 'activado' : 'desactivado'}.`);
          setAccion(null);
        },
      }
    );
  };

  return (
    <main className="mx-auto max-w-7xl space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-semibold">Usuarios</h1>
        <Boton onClick={() => setDialogoNuevo(true)}>Nuevo usuario interno</Boton>
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
        idRol={idRol}
        activo={activoParam}
        orden={orden}
        roles={roles.data ?? []}
        alCambiar={actualizar}
        alLimpiar={limpiar}
      />

      {consulta.isPending ? (
        <EstadoCarga mensaje="Cargando usuarios..." />
      ) : consulta.isError ? (
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
      ) : consulta.data.items.length === 0 ? (
        <EstadoVacio titulo="No hay usuarios" descripcion="Prueba con otros filtros." />
      ) : (
        <>
          <p className="text-sm text-gray-500">{consulta.data.totalRegistros} usuarios</p>

          <div className={`overflow-x-auto rounded-lg border border-gray-200 bg-white ${consulta.isPlaceholderData ? 'opacity-60' : ''}`}>
            <table className="w-full text-left text-sm">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-4 py-3">Nombre</th>
                  <th className="px-4 py-3">Correo</th>
                  <th className="px-4 py-3">Teléfono</th>
                  <th className="px-4 py-3">Rol</th>
                  <th className="px-4 py-3">Estado</th>
                  <th className="px-4 py-3">Creado</th>
                  <th className="px-4 py-3">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {consulta.data.items.map((u) => {
                  const esPropio = u.idUsuario === miId;
                  return (
                    <tr key={u.idUsuario} className="hover:bg-gray-50">
                      <td className="px-4 py-3 font-medium">
                        {u.nombres} {u.apellidos}
                        {esPropio && <span className="ml-2 text-xs font-normal text-gray-400">(tú)</span>}
                      </td>
                      <td className="px-4 py-3 text-gray-600">{u.correo}</td>
                      <td className="px-4 py-3 text-gray-600">{u.telefono ?? '—'}</td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${CLASE_ROL[u.rol] ?? CLASE_ROL.Cliente}`}>{u.rol}</span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${u.activo ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'}`}>
                          {u.activo ? 'Activo' : 'Inactivo'}
                        </span>
                      </td>
                      <td className="whitespace-nowrap px-4 py-3">{formatearFecha(u.fechaCreacion)}</td>
                      <td className="px-4 py-3">
                        <button
                          type="button"
                          disabled={esPropio && u.activo}
                          title={esPropio && u.activo ? 'No puedes desactivar tu propio usuario.' : undefined}
                          className="rounded-md border border-gray-300 px-2 py-1 text-xs font-medium hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50"
                          onClick={() => {
                            acciones.cambiarEstado.reset();
                            setAccion({ tipo: u.activo ? 'desactivar' : 'activar', usuario: u });
                          }}
                        >
                          {u.activo ? 'Desactivar' : 'Activar'}
                        </button>
                      </td>
                    </tr>
                  );
                })}
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

      <DialogoUsuario abierto={dialogoNuevo} alCerrar={() => setDialogoNuevo(false)} alCreado={setAviso} />

      <DialogoConfirmacion
        abierto={accion !== null}
        titulo={accion?.tipo === 'desactivar' ? 'Desactivar usuario' : 'Activar usuario'}
        mensaje={
          accion?.tipo === 'desactivar'
            ? `${accion.usuario.correo} no podrá iniciar sesión y se cerrarán sus sesiones activas. El usuario no se borra y su historial se conserva.`
            : `${accion?.usuario.correo ?? ''} podrá iniciar sesión de nuevo.`
        }
        textoConfirmar={accion?.tipo === 'desactivar' ? 'Desactivar' : 'Activar'}
        peligro={accion?.tipo === 'desactivar'}
        cargando={acciones.cambiarEstado.isPending}
        error={acciones.cambiarEstado.isError ? normalizarError(acciones.cambiarEstado.error).mensaje : null}
        alConfirmar={confirmar}
        alCerrar={() => setAccion(null)}
      />
    </main>
  );
}