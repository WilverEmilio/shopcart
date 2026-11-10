import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import type { ProductoDetalle } from '../../catalogo/tipos/catalogo';
import { imagenesFormEsquema } from '../esquemas/catalogoAdminEsquema';
import { useAccionesProducto } from '../hooks/useCatalogoAdmin';
import type { ImagenesFormulario } from '../tipos/catalogoAdmin';
import { EditorImagenes } from './EditorImagenes';

export function SeccionImagenes({ detalle }: { detalle: ProductoDetalle }) {
  const { imagenes: mutacion } = useAccionesProducto();

  const [valor, setValor] = useState<ImagenesFormulario>(() => {
    const ordenadas = [...detalle.imagenes].sort((a, b) => a.orden - b.orden);
    return {
      urls: ordenadas.map((i) => i.url),
      principal: Math.max(0, ordenadas.findIndex((i) => i.esPrincipal)),
    };
  });
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [mensaje, setMensaje] = useState<{ tipo: 'ok' | 'error'; texto: string } | null>(null);

  const guardar = (evento: FormEvent) => {
    evento.preventDefault();
    setMensaje(null);

    const resultado = imagenesFormEsquema.safeParse(valor);
    if (!resultado.success) {
      setErrores(erroresDeZod(resultado.error));
      return;
    }
    setErrores({});

    mutacion.mutate(
      {
        idProducto: detalle.producto.idProducto,
        lista: resultado.data.urls.map((url, i) => ({ url, orden: i, esPrincipal: i === resultado.data.principal })),
      },
      {
        onSuccess: () => setMensaje({ tipo: 'ok', texto: 'Imágenes guardadas.' }),
        onError: (error) => setMensaje({ tipo: 'error', texto: normalizarError(error).mensaje }),
      }
    );
  };

  return (
    <form onSubmit={guardar} noValidate className="tarjeta space-y-4 p-4 sm:p-5">
      <h2 className="text-lg font-semibold">Imágenes</h2>

      <EditorImagenes valor={valor} alCambiar={setValor} errores={errores} prefijo="" />

      {mensaje && (
        <p role={mensaje.tipo === 'ok' ? 'status' : 'alert'} className={`rounded-control border p-3 text-sm ${mensaje.tipo === 'ok' ? 'border-green-200 bg-green-50 text-green-800' : 'border-red-200 bg-red-50 text-red-700'}`}>
          {mensaje.texto}
        </p>
      )}

      <Boton type="submit" cargando={mutacion.isPending}>
        Guardar imágenes
      </Boton>
    </form>
  );
}