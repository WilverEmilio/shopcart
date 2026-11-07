import { StrictMode } from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import { clienteQuery } from './configuracion/clienteQuery';
import { restaurarSesion } from './modulos/autenticacion/servicios/autenticacionServicio';
import './index.css';

void restaurarSesion();

ReactDOM.createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={clienteQuery}>
      <App />
    </QueryClientProvider>
  </StrictMode>
);