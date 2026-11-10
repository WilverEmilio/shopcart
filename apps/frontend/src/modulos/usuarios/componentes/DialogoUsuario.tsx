import { useState, type FormEvent } from 'react';
import { Boton } from '../../../componentes/Boton';
import { CampoFormulario } from '../../../componentes/CampoFormulario';
import { Modal } from '../../../componentes/Modal';
import { erroresPorCampo, normalizarError } from '../../../servicios/errorServicio';
import { erroresDeZod } from '../../../utilidades/formularios';
import { usuarioNuevoFormEsquema } from '../esquemas/usuarioEsquema';
import { useAccionesUsuario } from '../hooks/useUsuarios';
import type { RolInterno, UsuarioFormulario } from '../tipos/usuarioAdmin';

interface Propiedades {
  abierto: boolean;
  alCerrar: () => void;
  alCreado: (mensaje: string) => void;
}

const VACIO: UsuarioFormulario = { correo: '', contrasena: '', nombres: '', apellidos: '', telefono: '', rol: 'Operador' };

function FormularioUsuario({ alCerrar, alCreado }: Omit<Propiedades, 'abierto'>) {
  const { crear } = useAccionesUsuario();

  const [datos, setDatos] = useState<UsuarioFormulario>(VACIO);
  const [mostrarContrasena, setMostrarContrasena] = useState(false);
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null);

  const cambiar = <K extends keyof UsuarioFormulario>(campo: K, valor: UsuarioFormulario[K]) =>
    setDatos((previos) => ({ ...previos, [campo]: valor }));

  const enviar = (evento: FormEvent) => {
    evento.preventDefault();
    setErrorGeneral(null);

    const resultado = usuarioNuevoFormEsquema.safeParse(datos);
    if (!resultado.success) {
      setErrores(erroresDeZod(resultado.error));
      return;
    }
    setErrores({});
    const v = resultado.data;

    crear.mutate(
      { ...v, telefono: v.telefono || null },
      {
        onSuccess: () => {
          alCreado(`Usuario ${v.correo} creado con rol ${v.rol}.`);
          alCerrar();
        },
        onError: (error) => {
          const porCampo = erroresPorCampo(error);
          const { codigo, mensaje } = normalizarError(error);
          if (codigo === 50010) setErrores({ correo: 'Este correo ya está registrado.' });
          else if (Object.keys(porCampo).length > 0) setErrores(porCampo);
          else setErrorGeneral(mensaje);
        },
      }
    );
  };

  return (
    <form onSubmit={enviar} noValidate className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <CampoFormulario etiqueta="Nombres" autoComplete="off" value={datos.nombres} onChange={(e) => cambiar('nombres', e.target.value)} error={errores.nombres} />
        <CampoFormulario etiqueta="Apellidos" autoComplete="off" value={datos.apellidos} onChange={(e) => cambiar('apellidos', e.target.value)} error={errores.apellidos} />
      </div>

      <CampoFormulario etiqueta="Correo electrónico" type="email" autoComplete="off" value={datos.correo} onChange={(e) => cambiar('correo', e.target.value)} error={errores.correo} />
      <CampoFormulario etiqueta="Teléfono (opcional)" type="tel" autoComplete="off" value={datos.telefono} onChange={(e) => cambiar('telefono', e.target.value)} error={errores.telefono} />

      <div>
        <CampoFormulario
          etiqueta="Contraseña inicial (mínimo 8 caracteres)"
          type={mostrarContrasena ? 'text' : 'password'}
          autoComplete="new-password"
          value={datos.contrasena}
          onChange={(e) => cambiar('contrasena', e.target.value)}
          error={errores.contrasena}
        />
        <label className="mt-1 flex items-center gap-2 text-xs text-gray-600">
          <input type="checkbox" checked={mostrarContrasena} onChange={(e) => setMostrarContrasena(e.target.checked)} />
          Mostrar contraseña
        </label>
      </div>

      <div>
        <label htmlFor="usuario-rol" className="mb-1 block text-sm font-medium text-gray-700">
          Rol
        </label>
        <select
          id="usuario-rol"
          value={datos.rol}
          onChange={(e) => cambiar('rol', e.target.value as RolInterno)}
          className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="Operador">Operador: gestiona pedidos e inventario</option>
          <option value="Administrador">Administrador: acceso completo</option>
        </select>
        {errores.rol && <p className="mt-1 text-sm text-red-600">{errores.rol}</p>}
      </div>

      {errorGeneral && (
        <p role="alert" className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {errorGeneral}
        </p>
      )}

      <div className="flex justify-end gap-2">
        <Boton variante="secundario" onClick={alCerrar} disabled={crear.isPending}>
          Cancelar
        </Boton>
        <Boton type="submit" cargando={crear.isPending}>
          Crear usuario
        </Boton>
      </div>
    </form>
  );
}

export function DialogoUsuario({ abierto, alCerrar, alCreado }: Propiedades) {
  return (
    <Modal abierto={abierto} titulo="Nuevo usuario interno" alCerrar={alCerrar}>
      <FormularioUsuario alCerrar={alCerrar} alCreado={alCreado} />
    </Modal>
  );
}