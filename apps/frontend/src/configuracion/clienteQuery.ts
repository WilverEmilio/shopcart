import { QueryClient } from '@tanstack/react-query';
import axios from 'axios';

export const clienteQuery = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      retry: (intentos, error) => {
        const estado = axios.isAxiosError(error) ? error.response?.status : undefined;
        if (estado !== undefined && estado >= 400 && estado < 500) return false;
        return intentos < 2;
      },
    },
  },
});