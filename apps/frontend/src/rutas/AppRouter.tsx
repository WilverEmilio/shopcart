import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { lazy } from 'react';
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
import { PaginaMisPedidos } from '../modulos/pedidos/paginas/PaginaMisPedidos';
import { PaginaNoEncontrada } from '../componentes/PaginaNoEncontrada';

const PaginaDashboard = lazy(() =>
  import('../modulos/reportes/paginas/PaginaDashboard').then((m) => ({ default: m.PaginaDashboard }))
);
const PaginaBitacora = lazy(() =>
  import('../modulos/bitacora/paginas/PaginaBitacora').then((m) => ({ default: m.PaginaBitacora }))
);
const PaginaCategoriasAdmin = lazy(()=>
  import('../modulos/catalogoAdmin/paginas/PaginaCategoriaAdmin').then((m)=>({default: m.PaginaCategoriasAdmin}))
)

const PaginaProductosAdmin = lazy(()=>
  import('../modulos/catalogoAdmin/paginas/PaginaProductosAdmin').then((m)=>({default: m.PaginaProductosAdmin}))
)

const PaginaProductoNuevo = lazy(()=>
  import('../modulos/catalogoAdmin/paginas/PaginaProductoNuevo').then((m)=>({default: m.PaginaProductoNuevo}))
)

const PaginaProductoEditar = lazy(()=>
  import('../modulos/catalogoAdmin/paginas/PaginaProductoEditar').then((m)=>({default: m.PaginaProductoEditar}))
)

const PaginaCuponesAdmin = lazy(()=>
  import('../modulos/cupones/paginas/PaginaCuponesAdmin').then((m)=>({default: m.PaginaCuponesAdmin}))
)

const PaginaUsuariosAdmin = lazy(()=>
  import('../modulos/usuarios/paginas/PaginaUsuarioAdmin').then((m)=>({default: m.PaginaUsuariosAdmin}))
)
const PaginaExistencias = lazy(()=>
  import('../modulos/inventario/paginas/PaginaExistencias').then((m)=>({default: m.PaginaExistencias}))
)

const PaginaKardex = lazy(()=>
  import('../modulos/inventario/paginas/PaginaKardex').then((m)=>({default: m.PaginaKardex}))
)

const PaginaConciliacion = lazy(()=>
  import('../modulos/inventario/paginas/PaginaConciliacion').then((m)=>({default: m.PaginaConciliacion}))
)

const PaginaPedidosGestion = lazy(()=>
  import('../modulos/pedidos/paginas/PaginaPedidosGestion').then((m)=>({default: m.PaginaPedidosGestion}))
)

const PaginaDetallePedidoGestion = lazy(()=>
  import('../modulos/pedidos/paginas/PaginaDetallePedidosGestion').then((m)=>({default: m.PaginaDetallePedidoGestion}))
)



const Provisional = ({ titulo }: { titulo: string }) => (
  <main className="mx-auto max-w-7xl p-6">
    <h1 className="text-2xl font-semibold">{titulo}</h1>
  </main>
);

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
            <Route path="/admin/dashboard" element={<PaginaDashboard />} />
            <Route path="/admin/bitacora" element={<PaginaBitacora />} />
          </Route>

          <Route path="*" element={<PaginaNoEncontrada/>}/>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}