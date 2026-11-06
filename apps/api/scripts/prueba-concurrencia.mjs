const BASE = process.env.API ?? 'http://localhost:3000/api';
const ID_VARIANTE = Number(process.env.ID_VARIANTE ?? 10);
const ID_ENVIO = Number(process.env.ID_ENVIO ?? 1);

const llamar = async (metodo, ruta, { cuerpo, token, encabezados } = {}) => {
    const r = await fetch(`${BASE}${ruta}`, {
        method: metodo,
        headers: { 'Content-Type': 'application/json', ...(token && { Authorization: `Bearer ${token}` }), ...encabezados },
        body: cuerpo ? JSON.stringify(cuerpo) : undefined
    });
    return { estado: r.status, cuerpo: await r.json() };
};

const exigir = (respuesta, esperado, paso) => {
    if (respuesta.estado !== esperado) {
        console.error(`Falló "${paso}": HTTP ${respuesta.estado}`, JSON.stringify(respuesta.cuerpo));
        process.exit(1);
    }
    return respuesta;
};

const crearCliente = async (n) => {
    const correo = `concurrencia${Date.now()}${n}@prueba.local`;
    const contrasena = 'ClavePrueba123!';

    exigir(await llamar('POST', '/autenticacion/registro',
        { cuerpo: { correo, contrasena, nombres: 'Cliente', apellidos: `Concurrente ${n}` } }), 201, 'registro');

    const sesion = exigir(await llamar('POST', '/autenticacion/iniciar-sesion',
        { cuerpo: { correo, contrasena } }), 200, 'inicio de sesión');
    const token = sesion.cuerpo.datos.tokenAcceso;

    exigir(await llamar('POST', '/carrito/items',
        { token, cuerpo: { idVariante: ID_VARIANTE, cantidad: 1 } }), 200, 'agregar al carrito');

    const dir = exigir(await llamar('POST', '/direcciones', {
        token, cuerpo: { nombreDestinatario: 'Prueba', telefono: '55555555', departamento: 'Quetzaltenango', municipio: 'Quetzaltenango', direccion: 'Zona 1' }
    }), 201, 'crear dirección');

    return { token, idDireccion: dir.cuerpo.datos.idDireccion, clave: `ultima-unidad-${Date.now()}-${n}` };
};

console.log('--- 1. Dos clientes compran la última unidad al mismo tiempo');
const clientes = await Promise.all([crearCliente(1), crearCliente(2)]);
const pagos = await Promise.all(clientes.map(c => llamar('POST', '/checkout/pagos', {
    token: c.token, encabezados: { 'Idempotency-Key': c.clave },
    cuerpo: { idDireccion: c.idDireccion, idMetodoEnvio: ID_ENVIO }
})));
pagos.forEach((p, i) => console.log(`cliente ${i + 1}:`, p.estado, p.cuerpo.mensaje));

const ganador = pagos.findIndex(p => p.estado === 201);
if (ganador === -1) { console.log('Nadie reservó: revisa que la variante tenga 1 unidad disponible.'); process.exit(1); }
console.log('ganador:', ganador, '| clave:', clientes[ganador].clave, '|', JSON.stringify(pagos[ganador].cuerpo));

console.log('--- 2. Doble clic en "pagar" (misma Idempotency-Key, en paralelo)');
const c = clientes[ganador];
const dobles = await Promise.all([1, 2].map(() => llamar('POST', '/checkout/pagos/confirmar', {
    token: c.token, encabezados: { 'Idempotency-Key': c.clave }, cuerpo: { tokenPago: 'tok_aprobado' }
})));
dobles.forEach((d, i) => console.log(`solicitud ${i + 1}:`, d.estado, d.cuerpo.datos?.numeroPedido ?? d.cuerpo.mensaje));