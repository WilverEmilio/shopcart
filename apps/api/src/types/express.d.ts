import type { DatosToken } from "../modulos/autenticacion/tipos/usuario.tipo";

declare global {
    namespace Express {
        interface Request {
            usuarioAutenticado?: DatosToken;
        }
    }
}

export {}