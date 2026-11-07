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
        className={`flex items-center justify-center bg-gray-100 text-sm text-gray-400 ${className}`}
      >
        Sin imagen
      </div>
    );
  }

  return <img src={url} alt={alt} loading="lazy" onError={() => setFallo(true)} className={className} />;
}