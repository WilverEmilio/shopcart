import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { ImagenProducto } from '../../../componentes/ImagenProducto';
import type { ImagenesFormulario } from '../tipos/catalogoAdmin';

interface Propiedades {
  valor: ImagenesFormulario;
  alCambiar: (valor: ImagenesFormulario) => void;
  errores: Record<string, string>;
  prefijo: string;
}

export function EditorImagenes({ valor, alCambiar, errores, prefijo }: Propiedades) {
  const clave = (campo: string) => (prefijo ? `${prefijo}.${campo}` : campo);

  const cambiarUrl = (indice: number, url: string) =>
    alCambiar({ ...valor, urls: valor.urls.map((u, i) => (i === indice ? url : u)) });

  const quitar = (indice: number) => {
    const principal = indice === valor.principal ? 0 : indice < valor.principal ? valor.principal - 1 : valor.principal;
    alCambiar({ urls: valor.urls.filter((_, i) => i !== indice), principal });
  };

  return (
    <div className="space-y-3">
      {valor.urls.length === 0 && (
        <p className="text-sm text-slate-600">Sin imágenes: la tienda mostrará un marcador.</p>
      )}

      {valor.urls.map((url, i) => (
        <div key={i} className="flex items-start gap-3">
          <ImagenProducto
            key={url}
            url={url.trim() || null}
            alt={`Vista previa de la imagen ${i + 1}`}
            className="h-14 w-14 shrink-0 rounded-control border border-slate-200 object-cover"
          />

          <div className="flex-1">
            <CampoFormulario
              etiqueta={`Imagen ${i + 1} (URL o ruta que empiece con /)`}
              maxLength={500}
              value={url}
              onChange={(e) => cambiarUrl(i, e.target.value)}
              error={errores[clave(`urls.${i}`)]}
            />
            <label className="mt-1 flex items-center gap-2 text-xs text-slate-600">
              <input
                type="radio"
                name={`principal-${prefijo || 'imagenes'}`}
                checked={valor.principal === i}
                onChange={() => alCambiar({ ...valor, principal: i })}
              />
              Imagen principal
            </label>
          </div>

          <button
            type="button"
            aria-label={`Quitar imagen ${i + 1}`}
            onClick={() => quitar(i)}
            className="mt-7 text-sm text-red-600 hover:underline"
          >
            Quitar
          </button>
        </div>
      ))}

      {errores[clave('urls')] && (
        <p role="alert" className="text-sm text-red-600">
          {errores[clave('urls')]}
        </p>
      )}

      <button
        type="button"
        onClick={() => alCambiar({ ...valor, urls: [...valor.urls, ''] })}
        className="inline-flex min-h-10 items-center text-sm font-medium text-marca-700 hover:underline"
      >
        + Agregar imagen
      </button>
    </div>
  );
}