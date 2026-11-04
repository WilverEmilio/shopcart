import { env } from "../config/env";
import { liberarReservasVencidasServicio } from "../modulos/inventario/servicio/reservas.servicio";
import { expirarPagosServicio } from "../modulos/checkout/servicios/pagos.servicios";

let temporizador: NodeJS.Timeout | null = null;
let enEjecucion = false; 

const ejecutarCiclo = async (): Promise<void>=> {
    if(enEjecucion) return;
    enEjecucion = true; 

    try{
        const reservas = await liberarReservasVencidasServicio();
        const pagos = await expirarPagosServicio();
        if (reservas > 0 || pagos > 0) {
      console.log(`Job de reservas: ${reservas} reserva(s) liberada(s), ${pagos} pago(s) expirado(s).`);
        }
    } catch (error) {
        console.error('Error en el job de reservas vencidas:', error);
    } finally {
        enEjecucion = false;
    }
};

export const iniciarJobReservas = (): void => {
    if(temporizador) return;
    temporizador = setInterval(() => {
        void ejecutarCiclo();
    }, env.jobs.reservasIntervaloSegundos * 1000);
    void ejecutarCiclo();
};

export const detenerJobReservas = (): void => {
    if (temporizador) {
        clearInterval(temporizador);
        temporizador = null;
    }
};