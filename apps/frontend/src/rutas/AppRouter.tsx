import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { RutasProtegidas } from './RutasProtegidas';

const Provisional = ({ titulo }: { titulo: string }) => (
  <main className="p-8">
    <h1 className="text-2xl font-semibold">{titulo}</h1>
  </main>
);

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Provisional titulo="ShopCart" />} />
        <Route path="/iniciar-sesion" element={<Provisional titulo="Iniciar sesión" />} />
        <Route path="/registro" element={<Provisional titulo="Registro" />} />
        <Route path="/sin-permiso" element={<Provisional titulo="No tienes permiso" />} />

        <Route element={<RutasProtegidas rolesPermitidos={['Cliente']} />}>
          <Route path="/mis-pedidos" element={<Provisional titulo="Mis pedidos" />} />
        </Route>

        <Route element={<RutasProtegidas rolesPermitidos={['Operador', 'Administrador']} />}>
          <Route path="/gestion" element={<Provisional titulo="Gestión" />} />
        </Route>

        <Route element={<RutasProtegidas rolesPermitidos={['Administrador']} />}>
          <Route path="/admin" element={<Provisional titulo="Administración" />} />
        </Route>

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}