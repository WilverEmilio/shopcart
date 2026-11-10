export function EstadoCarga({ mensaje = 'Cargando...' }: { mensaje?: string }) {
  return (
    <div role="status" className="flex min-h-48 items-center justify-center gap-3 p-10 text-sm text-slate-600">
      <span
        aria-hidden="true"
        className="h-5 w-5 animate-spin rounded-full border-2 border-slate-300 border-t-marca-600 motion-reduce:animate-none"
      />
      <span>{mensaje}</span>
    </div>
  );
}

/** Bloque gris animado para armar esqueletos de carga. */
export function Esqueleto({ className = '' }: { className?: string }) {
  const radio = className.includes('rounded') ? '' : 'rounded-md';
  return <div aria-hidden="true" className={`animate-pulse bg-slate-200 motion-reduce:animate-none ${radio} ${className}`} />;
}
