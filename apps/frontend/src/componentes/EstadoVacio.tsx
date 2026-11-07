interface Propiedades {
    titulo?: string;
    descripcion?: string;
}

export function EstadoVacio({
    titulo =  'Sin resultados',
    descripcion = 'No hay información para mostrar',
}: Propiedades) {
    return (
        <div className="p-10 text-center">
            <p className="font-medium text-gray-700">{titulo}</p>
            <p className="mt-1 text-sm text-gray-500">{descripcion}</p>
        </div>
    );
}