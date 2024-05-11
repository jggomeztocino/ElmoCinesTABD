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

//router.get('/reservas', listarReservas);
//router.get('/reservas/:id', listarReserva);
//router.post('/reservas', realizarReserva);
//router.delete('/reservas/:id', eliminarReserva);

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
    console.log(req.body);
    let connection;
    
});

module.exports = router;