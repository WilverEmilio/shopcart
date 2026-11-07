import type { RolUsuario } from '../tipos/usuario';

interface ElementoMenu {
  etiqueta: string;
  ruta: string;
  roles: RolUsuario[];
  visitante?: boolean;
}

const gestores: RolUsuario[] = ['Operador', 'Administrador'];
const admin: RolUsuario[] = ['Administrador'];

const elementosMenu: ElementoMenu[] = [
  { etiqueta: 'Catálogo', ruta: '/catalogo', roles: ['Cliente'], visitante: true },
  { etiqueta: 'Carrito', ruta: '/carrito', roles: ['Cliente'], visitante: true },
  { etiqueta: 'Mis pedidos', ruta: '/mis-pedidos', roles: ['Cliente'] },

  { etiqueta: 'Pedidos', ruta: '/gestion/pedidos', roles: gestores },
  { etiqueta: 'Inventario', ruta: '/gestion/inventario', roles: gestores },

  { etiqueta: 'Dashboard', ruta: '/admin/dashboard', roles: admin },
  { etiqueta: 'Productos', ruta: '/admin/productos', roles: admin },
  { etiqueta: 'Categorías', ruta: '/admin/categorias', roles: admin },
  { etiqueta: 'Cupones', ruta: '/admin/cupones', roles: admin },
  { etiqueta: 'Usuarios', ruta: '/admin/usuarios', roles: admin },
  { etiqueta: 'Bitácora', ruta: '/admin/bitacora', roles: admin },
];

export function menuPara(rol: RolUsuario | null): ElementoMenu[] {
  return elementosMenu.filter((e) => (rol ? e.roles.includes(rol) : e.visitante === true));
}