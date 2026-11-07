export function EstadoCarga({ mensaje = 'Cargando...' }: { mensaje?: string }) {
  return (
    <div role="status" className="flex items-center justify-center gap-3 p-10 text-gray-500">
      <span className="h-5 w-5 animate-spin rounded-full border-2 border-gray-300 border-t-gray-600" />
      <span>{mensaje}</span>
    </div>
  );
}