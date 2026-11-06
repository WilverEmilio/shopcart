import { listarBitacoraServicio } from '../servicios/bitacora.servicio';
import { manejar } from '../../../shared/utilidades/controlador';
import { obtenerIdActor } from '../../../shared/utilidades/actor';
import type { BitacoraQuery } from '../esquemas/bitacora.esquema';

export const listarBitacoraControlador = manejar(200, 'Bitácora obtenida correctamente',
    req => listarBitacoraServicio(obtenerIdActor(req), req.query as unknown as BitacoraQuery));