import { ejecutarProcedimiento } from "../../../shared/base_de_datos/ejecutar-procedimiento";

export const liberarReservasVencidas = async (

): Promise<number> => {
    const resultado = await ejecutarProcedimiento<{ ReservasLiberadas: number }> (
        'dbo.SP_Inventario_LiberarReservasVencidas'
    );
    return resultado.recordset[0]?.ReservasLiberadas ?? 0;
}