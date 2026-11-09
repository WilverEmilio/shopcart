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
      className={`m-auto max-h-[90vh] overflow-y-auto rounded-lg p-0 shadow-xl backdrop:bg-black/40 ${
        ancho === 'amplio' ? 'w-[min(44rem,94vw)]' : 'w-[min(32rem,92vw)]'
      }`}
    >
      {abierto && (
        <div className="p-6">
          <h2 id="titulo-modal" className="mb-4 text-lg font-semibold">
            {titulo}
          </h2>
          {children}
        </div>
      )}
    </dialog>
  );
}