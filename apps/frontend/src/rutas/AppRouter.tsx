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


const Provisional = ({ titulo }: { titulo: string }) => (
  <main className="mx-auto max-w-7xl p-6">
    <h1 className="text-2xl font-semibold">{titulo}</h1>
  </main>
);

const rutasGestion = [
  ['inventario', 'Inventario'],
] as const;

const rutasAdmin = [
  ['dashboard', 'Dashboard'],
  ['productos', 'Productos'],
  ['categorias', 'Categorías'],
  ['cupones', 'Cupones'],
  ['usuarios', 'Usuarios'],
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
            {rutasGestion.map(([ruta, titulo]) => (
              <Route key={ruta} path={`/gestion/${ruta}`} element={<Provisional titulo={titulo} />} />
            ))}
          </Route>

          <Route element={<RutasProtegidas rolesPermitidos={['Administrador']} />}>
            {rutasAdmin.map(([ruta, titulo]) => (
              <Route key={ruta} path={`/admin/${ruta}`} element={<Provisional titulo={titulo} />} />
            ))}
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}