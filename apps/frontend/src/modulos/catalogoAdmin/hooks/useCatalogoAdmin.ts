import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useSesionEstado } from '../../../estados/sesionEstado';
import {
  actualizarCategoria,
  actualizarProducto,
  actualizarVariante,
  cambiarEstadoCategoria,
  cambiarEstadoProducto,
  cambiarEstadoVariante,
  cambiarPrecioVariante,
  crearCategoria,
  crearProducto,
  crearVariante,
  eliminarCategoria,
  eliminarProducto,
  eliminarVariante,
  listarAtributos,
  listarCategoriasAdmin,
  reemplazarImagenes,
} from '../servicios/catalogoAdminServicio';
import type {
  DatosCategoria,
  DatosEdicionVariante,
  DatosProductoEdicion,
  DatosVariante,
  FiltrosCategoriasAdmin,
  ImagenProductoPayload,
} from '../tipos/catalogoAdmin';

export function useCategoriasAdmin(filtros: FiltrosCategoriasAdmin) {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: ['catalogo', 'categorias-admin', filtros],
    queryFn: ({ signal }) => listarCategoriasAdmin(filtros, signal),
    placeholderData: keepPreviousData,
    enabled: inicializada,
  });
}

export function useAtributos() {
  const inicializada = useSesionEstado((e) => e.inicializada);
  return useQuery({
    queryKey: ['catalogo', 'atributos'],
    queryFn: ({ signal }) => listarAtributos(signal),
    staleTime: 10 * 60_000,
    enabled: inicializada,
  });
}

function useRefrescarCatalogo() {
  const cliente = useQueryClient();
  return () =>
    Promise.all([
      cliente.invalidateQueries({ queryKey: ['catalogo'] }),
      cliente.invalidateQueries({ queryKey: ['inventario'] }),
    ]);
}

export function useAccionesCategoria() {
  const refrescar = useRefrescarCatalogo();

  const crear = useMutation({ mutationFn: (datos: DatosCategoria) => crearCategoria(datos), onSuccess: refrescar });
  const actualizar = useMutation({
    mutationFn: ({ idCategoria, datos }: { idCategoria: number; datos: DatosCategoria }) =>
      actualizarCategoria(idCategoria, datos),
    onSuccess: refrescar,
  });
  const cambiarEstado = useMutation({
    mutationFn: ({ idCategoria, activo }: { idCategoria: number; activo: boolean }) =>
      cambiarEstadoCategoria(idCategoria, activo),
    onSuccess: refrescar,
  });
  const eliminar = useMutation({ mutationFn: (idCategoria: number) => eliminarCategoria(idCategoria), onSuccess: refrescar });

  return { crear, actualizar, cambiarEstado, eliminar };
}

export function useAccionesProducto() {
  const refrescar = useRefrescarCatalogo();

  const crear = useMutation({ mutationFn: crearProducto, onSuccess: refrescar });
  const actualizar = useMutation({
    mutationFn: ({ idProducto, datos }: { idProducto: number; datos: DatosProductoEdicion }) =>
      actualizarProducto(idProducto, datos),
    onSuccess: refrescar,
  });
  const cambiarEstado = useMutation({
    mutationFn: ({ idProducto, activo }: { idProducto: number; activo: boolean }) =>
      cambiarEstadoProducto(idProducto, activo),
    onSuccess: refrescar,
  });
  const eliminar = useMutation({ mutationFn: (idProducto: number) => eliminarProducto(idProducto), onSuccess: refrescar });
  const imagenes = useMutation({
    mutationFn: ({ idProducto, lista }: { idProducto: number; lista: ImagenProductoPayload[] }) =>
      reemplazarImagenes(idProducto, lista),
    onSuccess: refrescar,
  });

  return { crear, actualizar, cambiarEstado, eliminar, imagenes };
}

export function useAccionesVariante() {
  const refrescar = useRefrescarCatalogo();

  const crear = useMutation({
    mutationFn: ({ idProducto, datos }: { idProducto: number; datos: DatosVariante }) => crearVariante(idProducto, datos),
    onSuccess: refrescar,
  });
  const actualizar = useMutation({
    mutationFn: ({ idVariante, datos }: { idVariante: number; datos: DatosEdicionVariante }) =>
      actualizarVariante(idVariante, datos),
    onSuccess: refrescar,
  });
  const cambiarPrecio = useMutation({
    mutationFn: ({ idVariante, precio }: { idVariante: number; precio: number }) =>
      cambiarPrecioVariante(idVariante, precio),
    onSuccess: refrescar,
  });
  const cambiarEstado = useMutation({
    mutationFn: ({ idVariante, activo }: { idVariante: number; activo: boolean }) =>
      cambiarEstadoVariante(idVariante, activo),
    onSuccess: refrescar,
  });
  const eliminar = useMutation({ mutationFn: (idVariante: number) => eliminarVariante(idVariante), onSuccess: refrescar });

  return { crear, actualizar, cambiarPrecio, cambiarEstado, eliminar };
}