import { useState } from 'react';
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom';
import { Boton } from '../../../componentes/Boton';
import { DialogoConfirmacion } from '../../../componentes/DialogoConfirmacion';
import { EstadoCarga } from '../../../componentes/EstadoCarga';
import { EstadoError } from '../../../componentes/EstadoError';
import { normalizarError } from '../../../servicios/errorServicio';
import { useDetalleProducto } from '../../catalogo/hooks/useCatalogo';
import { SeccionDatosProducto } from '../componentes/SeccionDatosProducto';
import { SeccionImagenes } from '../componentes/SeccionImagenes';
import { SeccionVariantes } from '../componentes/SeccionVariantes';
import { useAccionesProducto } from '../hooks/useCatalogoAdmin';

export function PaginaProductoEditar() {
  const { idProducto } = useParams();
  const id = Number(idProducto);
  const idValido = Number.isInteger(id) && id > 0;

  const navigate = useNavigate();
  const ubicacion = useLocation();
  const consulta = useDetalleProducto(idValido ? id : undefined);
  const { cambiarEstado, eliminar } = useAccionesProducto();

  const [aviso, setAviso] = useState<string | null>(
    (ubicacion.state as { aviso?: string } | null)?.aviso ?? null
  );
  const [dialogo, setDialogo] = useState<'estado' | 'eliminar' | null>(null);

  const enlaceVolver = (
    <Link to="/admin/productos" className="text-sm text-indigo-600 hover:underline">
      ← Volver a productos
    </Link>
  );

  if (!idValido) {
    return (
      <main className="mx-auto max-w-5xl p-6">
        <EstadoError error={new Error('El producto solicitado no es válido.')} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  if (consulta.isPending) return <EstadoCarga mensaje="Cargando el producto..." />;

  if (consulta.isError) {
    return (
      <main className="mx-auto max-w-5xl p-6">
        <EstadoError error={consulta.error} onReintentar={() => void consulta.refetch()} />
        <p className="text-center">{enlaceVolver}</p>
      </main>
    );
  }

  const detalle = consulta.data;
  const { producto } = detalle;

  const abrir = (cual: 'estado' | 'eliminar') => {
    cambiarEstado.reset();
    eliminar.reset();
    setDialogo(cual);
  };

  const confirmarEstado = () =>
    cambiarEstado.mutate(
      { idProducto: producto.idProducto, activo: !producto.activo },
      {
        onSuccess: () => {
          setAviso(`Producto ${producto.activo ? 'desactivado' : 'activado'}.`);
          setDialogo(null);
        },
      }
    );

  const confirmarEliminar = () =>
    eliminar.mutate(producto.idProducto, {
      onSuccess: (respuesta) => {
        if (respuesta.resultado === 'ELIMINADO') {
          navigate('/admin/productos', { replace: true });
        } else {
          setAviso(respuesta.mensaje);
          setDialogo(null);
        }
      },
    });

  return (
    <main className="mx-auto max-w-5xl space-y-6 p-6">
      {enlaceVolver}

      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">{producto.nombre}</h1>
          <p className="text-sm text-gray-500">
            {producto.categoria} ·{' '}
            <span className={producto.activo ? 'text-green-700' : 'text-gray-500'}>
              {producto.activo ? 'Activo en la tienda' : 'Inactivo (oculto en la tienda)'}
            </span>
          </p>
        </div>
        <div className="flex gap-2">
          <Boton variante="secundario" onClick={() => abrir('estado')}>
            {producto.activo ? 'Desactivar' : 'Activar'}
          </Boton>
          <Boton variante="peligro" onClick={() => abrir('eliminar')}>
            Eliminar
          </Boton>
        </div>
      </header>

      {aviso && (
        <p role="status" className="flex items-center justify-between rounded-md bg-green-50 p-3 text-sm text-green-800">
          {aviso}
          <button type="button" onClick={() => setAviso(null)} className="underline">
            Cerrar
          </button>
        </p>
      )}

      <SeccionDatosProducto key={`datos-${producto.idProducto}`} detalle={detalle} />
      <SeccionImagenes key={`imagenes-${producto.idProducto}`} detalle={detalle} />
      <SeccionVariantes detalle={detalle} alAviso={setAviso} />

      <DialogoConfirmacion
        abierto={dialogo === 'estado'}
        titulo={producto.activo ? 'Desactivar producto' : 'Activar producto'}
        mensaje={
          producto.activo
            ? 'El producto dejará de mostrarse en la tienda. Los pedidos existentes no se ven afectados.'
            : 'El producto volverá a mostrarse en la tienda.'
        }
        textoConfirmar={producto.activo ? 'Desactivar' : 'Activar'}
        peligro={producto.activo}
        cargando={cambiarEstado.isPending}
        error={cambiarEstado.isError ? normalizarError(cambiarEstado.error).mensaje : null}
        alConfirmar={confirmarEstado}
        alCerrar={() => setDialogo(null)}
      />

      <DialogoConfirmacion
        abierto={dialogo === 'eliminar'}
        titulo="Eliminar producto"
        mensaje="Si el producto nunca se vendió se eliminará por completo. Si tiene pedidos asociados no se borra: se desactiva para conservar el historial."
        textoConfirmar="Eliminar"
        peligro
        cargando={eliminar.isPending}
        error={eliminar.isError ? normalizarError(eliminar.error).mensaje : null}
        alConfirmar={confirmarEliminar}
        alCerrar={() => setDialogo(null)}
      />
    </main>
  );
}