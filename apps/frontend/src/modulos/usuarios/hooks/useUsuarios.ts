import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSesionEstado } from "../../../estados/sesionEstado";
import { cambiarEstadoUsuario, crearUsuarioInterno, listarRoles, listarUsuarios } from "../servicios/usuariosServicios";
import type { DatosUsuarioNuevo, FiltrosUsuarios } from "../tipos/usuarioAdmin";


export function useUsuarios(
    filtros: FiltrosUsuarios
){
    const inicializada = useSesionEstado((e) => e.inicializada);
    return useQuery({
        queryKey: ['usuarios', 'lista', filtros],
        queryFn: ({
            signal
        }) => listarUsuarios(
            filtros,
            signal
        ),
        placeholderData: keepPreviousData,
        enabled: inicializada,
    });
}

export function useRoles(){
    const inicializada = useSesionEstado((e) => e.inicializada);
    return useQuery({
        queryKey: ['usuarios', 'roles'],
        queryFn: ({
            signal
        }) => listarRoles(signal),
        staleTime: 10 * 60_000,
        retry: false,
        enabled: inicializada
    });
}

export function useAccionesUsuario(){
    const cliente = useQueryClient();
    const refrescar = () => cliente.invalidateQueries({
        queryKey: ['usuarios']
    });
    const crear = useMutation({
        mutationFn: (datos: DatosUsuarioNuevo) => crearUsuarioInterno(datos), onSuccess: refrescar
    });
    const cambiarEstado = useMutation({
    mutationFn: ({ 
        idUsuario, activo 
    }: { 
        idUsuario: number; 
        activo: boolean 
    }) => cambiarEstadoUsuario(
        idUsuario, 
        activo
    ),
    onSuccess: refrescar,
    });
    return {
        crear, cambiarEstado
    };
}