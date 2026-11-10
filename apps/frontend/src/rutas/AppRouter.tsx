import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { DisenoPrincipal } from '../diseños/DisenoPrincipal';
import { PaginaIniciarSesion } from '../modulos/autenticacion/paginas/PaginaIniciarSesion';
import { PaginaRegistro } from '../modulos/autenticacion/paginas/PaginasRegistro';
import { RutasProtegidas } from './RutasProtegidas';
import { PaginaCatalogo } from '../modulos/catalogo/paginas/PaginaCatalogo';
import { PaginaDetalleProducto } from '../modulos/catalogo/paginas/PaginaDetalleProducto';
import { PaginaCarrito } from '../modulos/carrito/paginas/PaginaCarrito';
import { PaginaCheckout } from '../modulos/checkout/paginas/PaginaCheckout';
import { PaginaPedidoConfirmado } from '../modulos/checkout/paginas/PaginaPedidoConfirmado';
import { PaginaDetalleMiPedido } from '../modulos/pedidos/paginas/PaginaDetalleMiPedido';
import { PaginaDetallePedidoGestion } from '../modulos/pedidos/paginas/PaginaDetallePedidosGestion';
import { PaginaMisPedidos } from '../modulos/pedidos/paginas/PaginaMisPedidos';
import { PaginaPedidosGestion } from '../modulos/pedidos/paginas/PaginaPedidosGestion';
import { PaginaConciliacion } from '../modulos/inventario/paginas/PaginaConciliacion';
import { PaginaExistencias } from '../modulos/inventario/paginas/PaginaExistencias';
import { PaginaKardex } from '../modulos/inventario/paginas/PaginaKardex';
import { PaginaCategoriasAdmin } from '../modulos/catalogoAdmin/paginas/PaginaCategoriaAdmin';
import { PaginaProductoEditar } from '../modulos/catalogoAdmin/paginas/PaginaProductoEditar';
import { PaginaProductoNuevo } from '../modulos/catalogoAdmin/paginas/PaginaProductoNuevo';
import { PaginaProductosAdmin } from '../modulos/catalogoAdmin/paginas/PaginaProductosAdmin';
import { PaginaCuponesAdmin } from '../modulos/cupones/paginas/PaginaCuponesAdmin';
import { PaginaUsuariosAdmin } from '../modulos/usuarios/paginas/PaginaUsuarioAdmin';
import { PaginaNoEncontrada } from '../componentes/PaginaNoEncontrada';

const Provisional = ({ titulo }: { titulo: string }) => (
  <main className="mx-auto max-w-7xl p-6">
    <h1 className="text-2xl font-semibold">{titulo}</h1>
  </main>
);

const rutasAdmin = [
  ['dashboard', 'Dashboard'],
  ['bitacora', 'Bitácora'],
] as const;

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<DisenoPrincipal />}>
        <Route path="/" element={<Navigate to="/catalogo" replace />} />
        <Route path="/catalogo" element={<PaginaCatalogo />} />
        <Route path="/catalogo/:idProducto" element={<PaginaDetalleProducto />} />
          <Route path="/carrito" element={<PaginaCarrito/>} />
          <Route path="/iniciar-sesion" element={<PaginaIniciarSesion />} />
          <Route path="/registro" element={<PaginaRegistro />} />
          <Route path="/sin-permiso" element={<Provisional titulo="No tienes permiso para ver esta página" />} />

          <Route element={<RutasProtegidas rolesPermitidos={['Cliente']} />}>
            <Route path="/mis-pedidos" element={<PaginaMisPedidos />} />
            <Route path="/mis-pedidos/:idPedido" element={<PaginaDetalleMiPedido />} />
            <Route path='/checkout' element={<PaginaCheckout/>}/>
            <Route path='/checkout/confirmacion' element={<PaginaPedidoConfirmado/>}/>
          </Route>

          <Route element={<RutasProtegidas rolesPermitidos={['Operador', 'Administrador']} />}>
            <Route path="/gestion/pedidos" element={<PaginaPedidosGestion />} />
            <Route path="/gestion/pedidos/:idPedido" element={<PaginaDetallePedidoGestion />} />
            <Route path="/gestion/inventario" element={<PaginaExistencias />} />
            <Route path="/gestion/inventario/kardex" element={<PaginaKardex />} />
            <Route path="/gestion/inventario/conciliacion" element={<PaginaConciliacion />} />
          </Route>

          <Route element={<RutasProtegidas rolesPermitidos={['Administrador']} />}>
            <Route path="/admin/categorias" element={<PaginaCategoriasAdmin />} />
            <Route path="/admin/productos" element={<PaginaProductosAdmin />} />
            <Route path="/admin/productos/nuevo" element={<PaginaProductoNuevo />} />
            <Route path="/admin/productos/:idProducto" element={<PaginaProductoEditar />} />
            <Route path="/admin/cupones" element={<PaginaCuponesAdmin />} />
            <Route path="/admin/usuarios" element={<PaginaUsuariosAdmin />} />
            {rutasAdmin.map(([ruta, titulo]) => (
              <Route key={ruta} path={`/admin/${ruta}`} element={<Provisional titulo={titulo} />} />
            ))}
          </Route>

          <Route path="*" element={<PaginaNoEncontrada/>}/>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}