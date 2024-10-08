'use strict';

const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
const oracledb = require('oracledb');


const app = express();
const router = express.Router();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));
app.use(cors());

async function openConnection() {
    try {
        return await oracledb.getConnection({
            user: process.env.ORACLE_USER,
            password: process.env.ORACLE_PASSWORD,
            connectionString: process.env.ORACLE_CONNECTION_STRING
        });
    } catch (err) {
        console.error('Error al conectarse a Oracle', err);
    }
}

router.get('/', async (req, res) => {
    let connection;
    try {
        connection = await openConnection();
        const result = await connection.execute(`BEGIN :cursor := ReservasPkg.listar_reservas(); END;`, {
            cursor: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        });
        const resultSet = result.outBinds.cursor;
        const rows = await resultSet.getRows();
        await resultSet.close();
        res.json(rows);
    } catch (error) {
        res.status(500).send('Error al obtener las reservas: ' + error.message);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err);
            }
        }
    }
});

router.get('/:id', async (req, res) => {
    let connection;
    try {
        const reservaId = req.params.id;
        connection = await openConnection();
        const result = await connection.execute(`BEGIN :cursor := ReservasPkg.listar_reserva(:id); END;`, {
            id: reservaId,
            cursor: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
        });
        const resultSet = result.outBinds.cursor;
        const rows = await resultSet.getRows();
        await resultSet.close();
        if (rows.length > 0) {
            res.json(rows[0]);
        } else {
            res.status(404).send('Reserva no encontrada');
        }
    } catch (error) {
        res.status(500).send('Error al obtener la reserva: ' + error.message);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err);
            }
        }
    }
});

router.post('/', async (req, res) => {
    let connection;
    // ReservasPkg.realizar_reserva(idSesion, Sala, Correo, Nombre, Telefono, Entradas, Butacas)
    try {
        connection = await openConnection();
        const { idSesion, Sala, Correo, Nombre, Telefono, Entradas, Butacas } = req.body;
        console.log(req.body);
        // Entradas es un array de objetos con la siguiente estructura:
        // id = secuencia_idEntrada.NEXTVAL, idMenu = menus[i], Descripcion = 'Entrada adulta', Precio: 6
        // o
        // id = secuencia_idEntrada.NEXTVAL, idMenu = menus[i], Descripcion = 'Entrada infantil', Precio: 4
        // Y debemos convertirlo a una Tipo de dato de Oracle con la siguiente estructura:
        // TipoEntradaArray(TipoEntrada(1, 1, 'Entrada adulta', 6), TipoEntrada(2, 1, 'Entrada infantil', 4)) con todas las entradas
        /*et EntradasSQL = '';
        Entradas.forEach((entrada) => {
            EntradasSQL += `TipoEntrada(${entrada.idEntrada}, ${entrada.idMenu}, '${entrada.Descripcion}', ${entrada.Precio}), `;
        });
        // Eliminamos la última coma y espacio y añadimos los paréntesis
        EntradasSQL = `TipoEntradaArray(${EntradasSQL.slice(0, -2)})`;*/

        const ButacasSeleccionadas = await connection.getDbObjectClass('BUTACASSELECCIONADAS');

        let butacasBind = {
            type: ButacasSeleccionadas,
            val: Butacas
        };

        const TipoEntrada = await connection.getDbObjectClass('TIPOENTRADA');
        const TipoEntradaArray = await connection.getDbObjectClass('TIPOENTRADAARRAY');

        let entradasArray = new TipoEntradaArray(); // Crear una instancia del VARRAY
        Entradas.forEach(entrada => {
            // Crea una nueva instancia de TipoEntrada
            let tempEntrada = new TipoEntrada({
                IDMENU: entrada.idMenu,
                DESCRIPCION: entrada.Descripcion,
                PRECIO: entrada.Precio
            });
            entradasArray.append(tempEntrada); // Usar append para añadir al VARRAY
        });


        let entradaBind = {
            type: TipoEntradaArray, // Usar el tipo correcto para el bind
            val: entradasArray
        };


        console.log(idSesion, Sala, Correo, Nombre, Telefono, entradaBind, butacasBind);

        await connection.execute(
            `BEGIN ReservasPkg.realizar_reserva(:idSesion, :Sala, :Correo, :Nombre, :Telefono, :Entradas, :Butacas); END;`,
            {
                idSesion,
                Sala,
                Correo,
                Nombre,
                Telefono,
                Entradas: { type: TipoEntradaArray, val: entradasArray },
                Butacas: { type: ButacasSeleccionadas, val: Butacas }
            }
        );        

        res.status(201).send('Reserva realizada');
    } catch (error) {
        console.error(error);
        res.status(500).send('Error al realizar la reserva: ' + error.message);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error(err);
            }
        }
    }
});

module.exports = router;