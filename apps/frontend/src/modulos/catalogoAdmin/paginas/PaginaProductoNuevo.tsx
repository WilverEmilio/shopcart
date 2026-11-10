import { useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { claseBoton } from '../../../componentes/estilosBoton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { erroresPorCampo, normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import { CamposVariante } from '../componentes/CamposVariante';
import { EditorImagenes } from '../componentes/EditorImagenes';
import { productoNuevoFormEsquema } from '../esquemas/catalogoAdminEsquema';
import { useAccionesProducto, useAtributos, useCategoriasAdmin } from '../hooks/useCatalogoAdmin';
import type { FiltrosCategoriasAdmin, ImagenesFormulario, VarianteFormulario } from '../tipos/catalogoAdmin';

const TODAS_LAS_CATEGORIAS: FiltrosCategoriasAdmin = {
  ordenarPor: 'Nombre',
  direccion: 'ASC',
  pagina: 1,
  registrosPorPagina: 100,
};

const varianteVacia = (): VarianteFormulario => ({ sku: '', precio: '', atributos: [] });

export function PaginaProductoNuevo() {
  const navigate = useNavigate();
  const categorias = useCategoriasAdmin(TODAS_LAS_CATEGORIAS);
  const atributos = useAtributos();
  const { crear } = useAccionesProducto();

  const [datos, setDatos] = useState({ idCategoria: '', nombre: '', descripcion: '' });
  const [variantes, setVariantes] = useState<VarianteFormulario[]>([varianteVacia()]);
  const [imagenes, setImagenes] = useState<ImagenesFormulario>({ urls: [], principal: 0 });
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const actualizarVariante = (indice: number, valor: VarianteFormulario) =>
    setVariantes((previas) => previas.map((v, i) => (i === indice ? valor : v)));

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    setErrorGeneral(null);

    const resultado = productoNuevoFormEsquema.safeParse({ ...datos, variantes, imagenes });
    if (!resultado.success) {
      setErrores(erroresDeZod(resultado.error));
      return;
    }
    setErrores({});

    const v = resultado.data;
    crear.mutate(
      {
        idCategoria: Number(v.idCategoria),
        nombre: v.nombre,
        descripcion: v.descripcion || null,
        variantes: v.variantes,
        imagenes: v.imagenes.urls.map((url, i) => ({ url, orden: i, esPrincipal: i === v.imagenes.principal })),
      },
      {
        onSuccess: (idProducto) =>
          navigate(`/admin/productos/${idProducto}`, { state: { aviso: 'Producto creado correctamente.' } }),
        onError: (error) => {
          const porCampo = erroresPorCampo(error);
          if (Object.keys(porCampo).length > 0) setErrores(porCampo);
          else setErrorGeneral(normalizarError(error).mensaje);
        },
      }
    );
  };

  return (
    <main className="mx-auto max-w-4xl space-y-6 px-4 py-6 sm:px-6 sm:py-8">
      <Link to="/admin/productos" className="inline-flex min-h-10 items-center text-sm font-medium text-marca-700 hover:underline">
        ← Volver a productos
      </Link>
      <h1 className="text-2xl font-bold sm:text-3xl">Nuevo producto</h1>

      <form onSubmit={enviar} noValidate className="space-y-8">
        <section className="tarjeta space-y-4 p-4 sm:p-5">
          <h2 className="text-lg font-semibold">Datos generales</h2>

          <CampoFormulario etiqueta="Nombre" maxLength={150} value={datos.nombre} onChange={(e) => setDatos({ ...datos, nombre: e.target.value })} error={errores.nombre} />

          <div>
            <label htmlFor="np-categoria" className="mb-1.5 block text-sm font-medium text-slate-700">
              Categoría
            </label>
            <select
              id="np-categoria"
              value={datos.idCategoria}
              onChange={(e) => setDatos({ ...datos, idCategoria: e.target.value })}
              className={`control ${errores.idCategoria ? 'border-red-500 hover:border-red-500' : ''}`}
            >
              <option value="">Selecciona una categoría...</option>
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
            <label htmlFor="np-descripcion" className="mb-1.5 block text-sm font-medium text-slate-700">
              Descripción (opcional)
            </label>
            <textarea
              id="np-descripcion"
              rows={4}
              maxLength={4000}
              value={datos.descripcion}
              onChange={(e) => setDatos({ ...datos, descripcion: e.target.value })}
              className="control"
            />
            {errores.descripcion && <p className="mt-1 text-sm text-red-600">{errores.descripcion}</p>}
          </div>
        </section>

        <section className="tarjeta space-y-4 p-4 sm:p-5">
          <div>
            <h2 className="text-lg font-semibold">Variantes</h2>
            <p className="text-sm text-slate-600">
              Cada variante tiene su propio SKU, precio y existencia (la existencia se carga después con una entrada de inventario).
            </p>
          </div>

          {variantes.map((variante, i) => (
            <div key={i} className="space-y-3 rounded-tarjeta border border-slate-200 bg-slate-50/50 p-4">
              <div className="flex items-center justify-between">
                <h3 className="font-medium">Variante {i + 1}</h3>
                {variantes.length > 1 && (
                  <button type="button" onClick={() => setVariantes(variantes.filter((_, k) => k !== i))} className="text-sm text-red-600 hover:underline">
                    Quitar variante
                  </button>
                )}
              </div>
              <CamposVariante
                valor={variante}
                alCambiar={(valor) => actualizarVariante(i, valor)}
                mostrarPrecio
                atributosDisponibles={atributos.data ?? []}
                errores={errores}
                prefijo={`variantes.${i}`}
              />
            </div>
          ))}

          {errores.variantes && (
            <p role="alert" className="text-sm text-red-600">
              {errores.variantes}
            </p>
          )}

          <Boton variante="secundario" onClick={() => setVariantes([...variantes, varianteVacia()])}>
            + Agregar variante
          </Boton>
        </section>

        <section className="tarjeta space-y-4 p-4 sm:p-5">
          <h2 className="text-lg font-semibold">Imágenes</h2>
          <EditorImagenes valor={imagenes} alCambiar={setImagenes} errores={errores} prefijo="imagenes" />
        </section>

        {errorGeneral && (
          <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
            {errorGeneral}
          </p>
        )}

        <div className="flex gap-3">
          <Boton type="submit" cargando={crear.isPending}>
            Crear producto
          </Boton>
          <Link to="/admin/productos" className={claseBoton('secundario')}>
            Cancelar
          </Link>
        </div>
      </form>
    </main>
  );
}