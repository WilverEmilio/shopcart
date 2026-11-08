import {useMutation, useQuery, useQueryClient} from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import { crearDireccion, listarDirecciones } from '../servicios/direccionesServicio';

export const CLAVE_DIRECCIONES = ['direcciones'] as const;

export function useDirecciones(){
    const inicializada = useSesionEstado((e) => e.inicializada);

    return useQuery({
        queryKey: CLAVE_DIRECCIONES,
        queryFn: ({
            signal
        }) => listarDirecciones(signal),
        enabled: inicializada
    });
}

export function useCrearDireccion(){
    const cliente = useQueryClient();

    return useMutation({
        mutationFn: crearDireccion,
        onSuccess: () =>  cliente.invalidateQueries({
            queryKey: CLAVE_DIRECCIONES
        })
    });
}