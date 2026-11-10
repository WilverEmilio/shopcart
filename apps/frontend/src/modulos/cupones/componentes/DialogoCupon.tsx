import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { Modal } from '../../../componentes/Modal';
import { erroresPorCampo, normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import { useCategoriasAdmin } from '../../catalogoAdmin/hooks/useCatalogoAdmin';
import type { FiltrosCategoriasAdmin } from '../../catalogoAdmin/tipos/catalogoAdmin';
import { aInputLocal } from '../constantes';
import { cuponEdicionFormEsquema, cuponNuevoFormEsquema } from '../esquemas/cuponEsquemas';
import { useAccionesCupon } from '../hooks/useCupones';
import type { Cupon, CuponFormulario } from '../tipos/cupon';

const TODAS_LAS_CATEGORIAS: FiltrosCategoriasAdmin = {
  ordenarPor: 'Nombre',
  direccion: 'ASC',
  pagina: 1,
  registrosPorPagina: 100,
};

interface Propiedades {
  abierto: boolean;
  cupon: Cupon | null;
  alCerrar: () => void;
  alGuardado: (mensaje: string) => void;
}

const claseSelect =
  'control';

function formularioInicial(cupon: Cupon | null): CuponFormulario {
  if (cupon) {
    return {
      codigo: cupon.codigo,
      descripcion: cupon.descripcion ?? '',
      tipoDescuento: cupon.tipoDescuento,
      valor: String(cupon.valor),
      idCategoria: cupon.idCategoria === null ? '' : String(cupon.idCategoria),
      montoMinimo: cupon.montoMinimo > 0 ? String(cupon.montoMinimo) : '',
      fechaInicio: aInputLocal(new Date(cupon.fechaInicio)),
      fechaFin: aInputLocal(new Date(cupon.fechaFin)),
      limiteUsosTotal: cupon.limiteUsosTotal === null ? '' : String(cupon.limiteUsosTotal),
      limiteUsosPorCliente: cupon.limiteUsosPorCliente === null ? '' : String(cupon.limiteUsosPorCliente),
    };
  }

  const ahora = new Date();
  const dentroDeUnMes = new Date(ahora.getTime() + 30 * 24 * 60 * 60 * 1000);
  return {
    codigo: '',
    descripcion: '',
    tipoDescuento: 'PORCENTAJE',
    valor: '',
    idCategoria: '',
    montoMinimo: '',
    fechaInicio: aInputLocal(ahora),
    fechaFin: aInputLocal(dentroDeUnMes),
    limiteUsosTotal: '',
    limiteUsosPorCliente: '',
  };
}

function FormularioCupon({ cupon, alCerrar, alGuardado }: Omit<Propiedades, 'abierto'>) {
  const { crear, actualizar } = useAccionesCupon();
  const categorias = useCategoriasAdmin(TODAS_LAS_CATEGORIAS);

  const [datos, setDatos] = useState<CuponFormulario>(() => formularioInicial(cupon));
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const pendiente = crear.isPending || actualizar.isPending;
  const cambiar = <K extends keyof CuponFormulario>(campo: K, valor: CuponFormulario[K]) =>
    setDatos((previos) => ({ ...previos, [campo]: valor }));

  const alError = (error: unknown) => {
    const porCampo = erroresPorCampo(error);
    if (Object.keys(porCampo).length > 0) setErrores(porCampo);
    else setErrorGeneral(normalizarError(error).mensaje);
  };

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    setErrorGeneral(null);

    const alExito = (mensaje: string) => () => {
      alGuardado(mensaje);
      alCerrar();
    };

    if (cupon) {
      const resultado = cuponEdicionFormEsquema.safeParse(datos);
      if (!resultado.success) {
        setErrores(erroresDeZod(resultado.error));
        return;
      }
      const v = resultado.data;

      if (v.limiteUsosTotal !== null && v.limiteUsosTotal < cupon.usosActuales) {
        setErrores({ limiteUsosTotal: `No puede ser menor a los usos ya registrados (${cupon.usosActuales}).` });
        return;
      }
      setErrores({});

      actualizar.mutate(
        { idCupon: cupon.idCupon, datos: { ...v, descripcion: v.descripcion || null } },
        { onSuccess: alExito(`Cupón ${cupon.codigo} actualizado.`), onError: alError }
      );
    } else {
      const resultado = cuponNuevoFormEsquema.safeParse(datos);
      if (!resultado.success) {
        setErrores(erroresDeZod(resultado.error));
        return;
      }
      setErrores({});
      const v = resultado.data;

      crear.mutate(
        { ...v, descripcion: v.descripcion || null },
        { onSuccess: alExito(`Cupón ${v.codigo.toUpperCase()} creado.`), onError: alError }
      );
    }
  };

  return (
    <form onSubmit={enviar} noValidate className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2">
        <CampoFormulario
          etiqueta="Código"
          maxLength={30}
          disabled={cupon !== null}
          className="uppercase"
          value={datos.codigo}
          onChange={(e) => cambiar('codigo', e.target.value)}
          error={errores.codigo}
        />
        <CampoFormulario
          etiqueta="Descripción (opcional)"
          maxLength={255}
          value={datos.descripcion}
          onChange={(e) => cambiar('descripcion', e.target.value)}
          error={errores.descripcion}
        />
      </div>
      {cupon && <p className="-mt-3 text-xs text-gray-500">El código no se puede cambiar una vez creado.</p>}

      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="cupon-tipo" className="mb-1.5 block text-sm font-medium text-gray-700">
            Tipo de descuento
          </label>
          <select
            id="cupon-tipo"
            className={claseSelect}
            value={datos.tipoDescuento}
            onChange={(e) => cambiar('tipoDescuento', e.target.value as CuponFormulario['tipoDescuento'])}
          >
            <option value="PORCENTAJE">Porcentaje (%)</option>
            <option value="MONTO_FIJO">Monto fijo (Q)</option>
          </select>
        </div>
        <CampoFormulario
          etiqueta={datos.tipoDescuento === 'PORCENTAJE' ? 'Valor (1 a 100 %)' : 'Valor (Q)'}
          inputMode="decimal"
          value={datos.valor}
          onChange={(e) => cambiar('valor', e.target.value)}
          error={errores.valor}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="cupon-categoria" className="mb-1.5 block text-sm font-medium text-gray-700">
            Aplica a
          </label>
          <select
            id="cupon-categoria"
            className={claseSelect}
            value={datos.idCategoria}
            onChange={(e) => cambiar('idCategoria', e.target.value)}
          >
            <option value="">Todo el carrito</option>
            {(categorias.data?.categorias ?? []).map((c) => (
              <option key={c.idCategoria} value={c.idCategoria}>
                Solo la categoría {c.nombre}
              </option>
            ))}
          </select>
          {errores.idCategoria && <p className="mt-1 text-sm text-red-600">{errores.idCategoria}</p>}
        </div>
        <CampoFormulario
          etiqueta="Compra mínima (Q, opcional)"
          inputMode="decimal"
          value={datos.montoMinimo}
          onChange={(e) => cambiar('montoMinimo', e.target.value)}
          error={errores.montoMinimo}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <CampoFormulario
          etiqueta="Vigente desde"
          type="datetime-local"
          value={datos.fechaInicio}
          onChange={(e) => cambiar('fechaInicio', e.target.value)}
          error={errores.fechaInicio}
        />
        <CampoFormulario
          etiqueta="Vigente hasta"
          type="datetime-local"
          value={datos.fechaFin}
          onChange={(e) => cambiar('fechaFin', e.target.value)}
          error={errores.fechaFin}
        />
      </div>
      <p className="-mt-3 text-xs text-gray-500">Las fechas se interpretan en tu hora local.</p>

      <div className="grid gap-4 sm:grid-cols-2">
        <CampoFormulario
          etiqueta="Límite total de usos (vacío = sin límite)"
          inputMode="numeric"
          value={datos.limiteUsosTotal}
          onChange={(e) => cambiar('limiteUsosTotal', e.target.value)}
          error={errores.limiteUsosTotal}
        />
        <CampoFormulario
          etiqueta="Límite por cliente (vacío = sin límite)"
          inputMode="numeric"
          value={datos.limiteUsosPorCliente}
          onChange={(e) => cambiar('limiteUsosPorCliente', e.target.value)}
          error={errores.limiteUsosPorCliente}
        />
      </div>

      {errorGeneral && (
        <p role="alert" className="rounded-control border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {errorGeneral}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={pendiente}>
          Cancelar
        </Boton>
        <Boton type="submit" cargando={pendiente}>
          {cupon ? 'Guardar cambios' : 'Crear cupón'}
        </Boton>
      </div>
    </form>
  );
}

export function DialogoCupon({ abierto, cupon, alCerrar, alGuardado }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo={cupon ? `Editar cupón ${cupon.codigo}` : 'Nuevo cupón'} ancho="amplio" alCerrar={alCerrar}>
      <FormularioCupon cupon={cupon} alCerrar={alCerrar} alGuardado={alGuardado} />
    </Modal>
  );
}