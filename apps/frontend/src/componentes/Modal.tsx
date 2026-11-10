import { useEffect, useRef, type ReactNode } from 'react';

interface Propiedades {
  abierto: boolean;
  titulo: string;
  alCerrar: () => void;
  ancho?: 'normal' | 'amplio';
  children: ReactNode;
}

export function Modal({ abierto, titulo, alCerrar, ancho = 'normal', children }: Propiedades) {
  const dialogo = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const elemento = dialogo.current;
    if (!elemento) return;
    if (abierto && !elemento.open) elemento.showModal();
    if (!abierto && elemento.open) elemento.close();
  }, [abierto]);

  return (
    <dialog
      ref={dialogo}
      onClose={alCerrar}
      aria-labelledby="titulo-modal"
      className={`m-auto max-h-[90vh] overflow-y-auto rounded-tarjeta p-0 shadow-elevada backdrop:bg-gray-900/50 backdrop:backdrop-blur-[2px] ${
        ancho === 'amplio' ? 'w-[min(44rem,94vw)]' : 'w-[min(32rem,92vw)]'
      }`}
    >
      {abierto && (
        <div className="p-5 sm:p-6">
          <div className="mb-4 flex items-start justify-between gap-4">
            <h2 id="titulo-modal" className="text-lg font-semibold">
              {titulo}
            </h2>
            <button
              type="button"
              aria-label="Cerrar"
              onClick={() => dialogo.current?.close()}
              className="-m-2 flex h-10 w-10 shrink-0 items-center justify-center rounded-control text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700"
            >
              <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5">
                <path strokeLinecap="round" d="M6 6l12 12M18 6 6 18" />
              </svg>
            </button>
          </div>
          {children}
        </div>
      )}
    </dialog>
  );
}
