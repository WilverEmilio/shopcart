import { normalizarError } from "../../servicios/errorServicio";

interface Propiedades {
    error: unknown;
    onReintentar?: () => void;
}

export function EstadoError({
    error,
    onReintentar
}: Propiedades) {
    const {mensaje} = normalizarError(error);

    return(
        <div role="alert" className="p-10 text-center">
            <p className="font-medium text-red-700">{mensaje}</p>
            {onReintentar && (
                <button type="button" onClick={onReintentar} className="mt-3 rounded-md border border-gray-300 px-4 py-2 text-sm hover:bg-gray-100">
                    Reintentar
                </button>
            )}
        </div>
    )
}