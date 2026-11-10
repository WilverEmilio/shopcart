import { useState } from 'react';
import { DialogoConfirmacion } from '../../../componentes/DialogoConfirmacion';
import { Boton } from '../../../componentes/Boton';
import { normalizarError } from '../../../servicios/errorServicio';
import { formatearMoneda } from '../../../utilidades/formato';
import type { ProductoDetalle, VarianteProducto } from '../../catalogo/tipos/catalogo';
import { useAccionesVariante, useAtributos } from '../hooks/useCatalogoAdmin';
import { DialogoPrecio } from './DialogoPrecio';
import { DialogoVariante } from './DialogoVariante';

type Dialogo =
  | { tipo: 'crear' }
  | { tipo: 'editar'; variante: VarianteProducto }
  | { tipo: 'precio'; variante: VarianteProducto }
  | { tipo: 'estado'; variante: VarianteProducto }
  | { tipo: 'eliminar'; variante: VarianteProducto }
  | null;

interface Propiedades {
  detalle: ProductoDetalle;
  alAviso: (mensaje: string) => void;
}

const claseBotonFila = 'boton-fila';

export function SeccionVariantes({ detalle, alAviso }: Propiedades) {
  const atributos = useAtributos();
  const acciones = useAccionesVariante();
  const [dialogo, setDialogo] = useState<Dialogo>(null);

  const atributosDe = (idVariante: number) =>
    detalle.atributos.filter((a) => a.idVariante === idVariante).map((a) => ({ atributo: a.atributo, valor: a.valor }));

  const textoAtributos = (idVariante: number) =>
    atributosDe(idVariante).map((a) => `${a.atributo}: ${a.valor}`).join(' · ') || '—';

  const abrir = (nuevo: Dialogo) => {
    acciones.cambiarEstado.reset();
    acciones.eliminar.reset();
    setDialogo(nuevo);
  };

  const confirmarEstado = () => {
    if (dialogo?.tipo !== 'estado') return;
    const { variante } = dialogo;
    acciones.cambiarEstado.mutate(
      { idVariante: variante.idVariante, activo: !variante.activo },
      {
        onSuccess: () => {
          alAviso(`Variante ${variante.sku} ${variante.activo ? 'desactivada' : 'activada'}.`);
          setDialogo(null);
        },
      }
    );
  };

  const confirmarEliminar = () => {
    if (dialogo?.tipo !== 'eliminar') return;
    acciones.eliminar.mutate(dialogo.variante.idVariante, {
      onSuccess: (respuesta) => {
        alAviso(respuesta.mensaje);
        setDialogo(null);
      },
    });
  };

  const variante = dialogo && dialogo.tipo !== 'crear' ? dialogo.variante : null;

  return (
    <section className="tarjeta space-y-4 p-4 sm:p-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="text-lg font-semibold">Variantes</h2>
        <Boton onClick={() => abrir({ tipo: 'crear' })}>Agregar variante</Boton>
      </div>

      <div className="overflow-x-auto">
        <table className="tabla">
          <thead>
            <tr>
              <th className="px-4 py-3">SKU</th>
              <th className="px-4 py-3">Atributos</th>
              <th className="px-4 py-3 text-right">Precio</th>
              <th className="px-4 py-3 text-right">Disponible</th>
              <th className="px-4 py-3">Estado</th>
              <th className="px-4 py-3">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {detalle.variantes.map((v) => (
              <tr key={v.idVariante}>
                <td className="px-4 py-3 font-mono text-xs">{v.sku}</td>
                <td className="px-4 py-3 text-gray-600">{textoAtributos(v.idVariante)}</td>
                <td className="whitespace-nowrap px-4 py-3 text-right">{formatearMoneda(v.precio)}</td>
                <td className="px-4 py-3 text-right">
                  {v.existenciaDisponible}
                  {v.existenciaFisica !== null && <span className="block text-xs text-gray-500">física {v.existenciaFisica}</span>}
                </td>
                <td className="px-4 py-3">
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${v.activo ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-700'}`}>
                    {v.activo ? 'Activa' : 'Inactiva'}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-1">
                    <button type="button" className={claseBotonFila} onClick={() => abrir({ tipo: 'editar', variante: v })}>
                      Editar
                    </button>
                    <button type="button" className={claseBotonFila} onClick={() => abrir({ tipo: 'precio', variante: v })}>
                      Precio
                    </button>
                    <button type="button" className={claseBotonFila} onClick={() => abrir({ tipo: 'estado', variante: v })}>
                      {v.activo ? 'Desactivar' : 'Activar'}
                    </button>
                    <button type="button" className={`${claseBotonFila} text-red-600`} onClick={() => abrir({ tipo: 'eliminar', variante: v })}>
                      Eliminar
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <DialogoVariante
        abierto={dialogo?.tipo === 'crear' || dialogo?.tipo === 'editar'}
        idProducto={detalle.producto.idProducto}
        variante={dialogo?.tipo === 'editar' ? { idVariante: dialogo.variante.idVariante, sku: dialogo.variante.sku, atributos: atributosDe(dialogo.variante.idVariante) } : null}
        atributosDisponibles={atributos.data ?? []}
        alCerrar={() => setDialogo(null)}
        alGuardada={alAviso}
      />

      <DialogoPrecio
        abierto={dialogo?.tipo === 'precio'}
        variante={dialogo?.tipo === 'precio' ? { idVariante: dialogo.variante.idVariante, sku: dialogo.variante.sku, precio: dialogo.variante.precio } : null}
        alCerrar={() => setDialogo(null)}
        alGuardado={alAviso}
      />

      <DialogoConfirmacion
        abierto={dialogo?.tipo === 'estado'}
        titulo={variante?.activo ? 'Desactivar variante' : 'Activar variante'}
        mensaje={
          variante?.activo
            ? `La variante ${variante.sku} dejará de venderse en la tienda.`
            : `La variante ${variante?.sku ?? ''} volverá a venderse en la tienda.`
        }
        textoConfirmar={variante?.activo ? 'Desactivar' : 'Activar'}
        peligro={variante?.activo ?? false}
        cargando={acciones.cambiarEstado.isPending}
        error={acciones.cambiarEstado.isError ? normalizarError(acciones.cambiarEstado.error).mensaje : null}
        alConfirmar={confirmarEstado}
        alCerrar={() => setDialogo(null)}
      />

      <DialogoConfirmacion
        abierto={dialogo?.tipo === 'eliminar'}
        titulo="Eliminar variante"
        mensaje={`Se eliminará la variante ${variante?.sku ?? ''}. Si ya tiene historial de ventas o de inventario, no se borra: se desactiva.`}
        textoConfirmar="Eliminar"
        peligro
        cargando={acciones.eliminar.isPending}
        error={acciones.eliminar.isError ? normalizarError(acciones.eliminar.error).mensaje : null}
        alConfirmar={confirmarEliminar}
        alCerrar={() => setDialogo(null)}
      />
    </section>
  );
}