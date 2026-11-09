import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { erroresPorCampo, normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import type { ProductoDetalle } from '../../catalogo/tipos/catalogo';
import { datosProductoFormEsquema } from '../esquemas/catalogoAdminEsquema';
import { useAccionesProducto, useCategoriasAdmin } from '../hooks/useCatalogoAdmin';
import type { FiltrosCategoriasAdmin } from '../tipos/catalogoAdmin';

const TODAS_LAS_CATEGORIAS: FiltrosCategoriasAdmin = {
  ordenarPor: 'Nombre',
  direccion: 'ASC',
  pagina: 1,
  registrosPorPagina: 100,
};

export function SeccionDatosProducto({ detalle }: { detalle: ProductoDetalle }) {
  const { producto } = detalle;
  const categorias = useCategoriasAdmin(TODAS_LAS_CATEGORIAS);
  const { actualizar } = useAccionesProducto();

  const [datos, setDatos] = useState({
    idCategoria: String(producto.idCategoria),
    nombre: producto.nombre,
    descripcion: producto.descripcion ?? '',
  });
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [mensaje, setMensaje] = useState<{ tipo: 'ok' | 'error'; texto: string } | null>(null);

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    setMensaje(null);

    const resultado = datosProductoFormEsquema.safeParse(datos);
    if (!resultado.success) {
      setErrores(erroresDeZod(resultado.error));
      return;
    }
    setErrores({});

    actualizar.mutate(
      {
        idProducto: producto.idProducto,
        datos: {
          idCategoria: Number(resultado.data.idCategoria),
          nombre: resultado.data.nombre,
          descripcion: resultado.data.descripcion || null,
        },
      },
      {
        onSuccess: () => setMensaje({ tipo: 'ok', texto: 'Datos guardados.' }),
        onError: (error) => {
          const porCampo = erroresPorCampo(error);
          if (Object.keys(porCampo).length > 0) setErrores(porCampo);
          else setMensaje({ tipo: 'error', texto: normalizarError(error).mensaje });
        },
      }
    );
  };

  return (
    <form onSubmit={enviar} noValidate className="space-y-4 rounded-lg border border-gray-200 bg-white p-5">
      <h2 className="text-lg font-semibold">Datos generales</h2>

      <CampoFormulario etiqueta="Nombre" maxLength={150} value={datos.nombre} onChange={(e) => setDatos({ ...datos, nombre: e.target.value })} error={errores.nombre} />

      <div>
        <label htmlFor="ep-categoria" className="mb-1 block text-sm font-medium text-gray-700">
          Categoría
        </label>
        <select
          id="ep-categoria"
          value={datos.idCategoria}
          onChange={(e) => setDatos({ ...datos, idCategoria: e.target.value })}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
        >
          {(categorias.data?.categorias ?? []).map((c) => (
            <option key={c.idCategoria} value={c.idCategoria}>
              {c.nombre}
              {c.activo ? '' : ' (inactiva)'}
            </option>
          ))}
        </select>
        {categorias.isError && (
          <p role="alert" className="mt-1 text-sm text-red-600">
            No se pudieron cargar las categorías. Recarga la página.
          </p>
        )}
        {categorias.isSuccess && categorias.data.categorias.length === 0 && (
          <p className="mt-1 text-sm text-amber-600">
            Aún no hay categorías: crea una en Categorías antes de agregar productos.
          </p>
        )}
        {errores.idCategoria && <p className="mt-1 text-sm text-red-600">{errores.idCategoria}</p>}
      </div>

      <div>
        <label htmlFor="ep-descripcion" className="mb-1 block text-sm font-medium text-gray-700">
          Descripción
        </label>
        <textarea
          id="ep-descripcion"
          rows={4}
          maxLength={4000}
          value={datos.descripcion}
          onChange={(e) => setDatos({ ...datos, descripcion: e.target.value })}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
        />
        {errores.descripcion && <p className="mt-1 text-sm text-red-600">{errores.descripcion}</p>}
      </div>

      {mensaje && (
        <p role={mensaje.tipo === 'ok' ? 'status' : 'alert'} className={`rounded-md p-3 text-sm ${mensaje.tipo === 'ok' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-700'}`}>
          {mensaje.texto}
        </p>
      )}

      <Boton type="submit" cargando={actualizar.isPending}>
        Guardar datos
      </Boton>
    </form>
  );
}