import { useState } from 'react';

interface Propiedades {
  url: string | null;
  alt: string;
  className?: string;
}

export function ImagenProducto({ url, alt, className = '' }: Propiedades) {
  const [fallo, setFallo] = useState(false);

  if (!url || fallo) {
    return (
      <div
        role="img"
        aria-label={alt}
        className={`flex flex-col items-center justify-center gap-1 bg-slate-100 text-xs text-slate-500 ${className}`}
      >
        <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="h-1/4 max-h-10 w-1/4 max-w-10 text-slate-400">
          <rect x="3" y="4" width="18" height="16" rx="2" />
          <circle cx="9" cy="10" r="2" />
          <path strokeLinejoin="round" d="m21 16-5-5-9 9" />
        </svg>
        <span className="hidden sm:block">Sin imagen</span>
      </div>
    );
  }

  return <img src={url} alt={alt} loading="lazy" onError={() => setFallo(true)} className={className} />;
}
