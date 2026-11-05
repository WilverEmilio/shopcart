import bcrypt from 'bcrypt';
import sql from 'mssql';
import { env } from '../config/env';
import { ejecutarProcedimiento } from '../shared/base_de_datos/ejecutar-procedimiento';

const RONDAS_BCRYPT = 10;

const existeUsuario = async (correo: string): Promise<boolean> => {
    const r = await ejecutarProcedimiento('dbo.SP_Usuarios_ObtenerPorCorreo',
        s => { s.input('Correo', sql.NVarChar(255), correo); });
    return r.recordset.length > 0;
};

export const crearUsuariosPrueba = async (idAdministrador: number): Promise<void> => {
    const { operador, cliente } = env.usuariosPrueba;

    if (operador && !(await existeUsuario(operador.correo))) {
        const hash = await bcrypt.hash(operador.contrasena, RONDAS_BCRYPT);
        await ejecutarProcedimiento('dbo.SP_Usuarios_CrearUsuarioInterno', s => {
            s.input('IDUsuarioActor', sql.Int, idAdministrador);
            s.input('Correo', sql.NVarChar(255), operador.correo);
            s.input('PasswordHash', sql.NVarChar(255), hash);
            s.input('Nombres', sql.NVarChar(100), 'Operador');
            s.input('Apellidos', sql.NVarChar(100), 'Prueba');
            s.input('NombreRol', sql.NVarChar(50), 'Operador');
        });
        console.log('Operador de prueba creado.');
    }

    if (cliente && !(await existeUsuario(cliente.correo))) {
        const hash = await bcrypt.hash(cliente.contrasena, RONDAS_BCRYPT);
        await ejecutarProcedimiento('dbo.SP_Usuarios_RegistrarCliente', s => {
            s.input('Correo', sql.NVarChar(255), cliente.correo);
            s.input('PasswordHash', sql.NVarChar(255), hash);
            s.input('Nombres', sql.NVarChar(100), 'Cliente');
            s.input('Apellidos', sql.NVarChar(100), 'Prueba');
        });
        console.log('Cliente de prueba creado.');
    }
};