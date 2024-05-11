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

router.get('/:movieId', async (req, res) => {
    let connection;
    try {
        connection = await openConnection();
        const movieId = req.params.movieId;
        const result = await connection.execute(
            `BEGIN :ret := SesionesPkg.sesiones_con_butacas_libres(:movieId); END;`,
            {
                movieId: movieId,
                ret: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );
        
        const resultSet = result.outBinds.ret;
        const sessions = [];

        let row;
        while ((row = await resultSet.getRow())) {
            sessions.push({
                idSesion: row[0],
                fechaHora: row[1]
            });
        }

        await resultSet.close();
        res.json(sessions);
    } catch (error) {
        res.status(500).send(`Error al obtener las sesiones: ${error.message}`);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (error) {
                console.error('Error al cerrar la conexión a Oracle', error);
            }
        }
    }
});

router.get('/:movieId/:sessionId', async (req, res) => {
    let connection;
    try {
        connection = await openConnection();
        const sessionId = req.params.sessionId;
        const result = await connection.execute(
            `BEGIN :ret := SesionesPkg.listar_sesion(:sessionId); END;`,
            {
                sessionId: sessionId,
                ret: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );

        const resultSet = result.outBinds.ret;
        const session = await resultSet.getRow();

        if (session) {
            res.json({
                idSesion: session[0],
                detalles: session.slice(1)  // Rest of session details
            });
        } else {
            res.status(404).send('Sesión no encontrada');
        }

        await resultSet.close();
    } catch (error) {
        res.status(500).send(`Error al obtener la sesión: ${error.message}`);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (error) {
                console.error('Error al cerrar la conexión a Oracle', error);
            }
        }
    }
});

router.delete('/:movieId/:sessionId', async (req, res) => {
    let connection;
    try {
        connection = await openConnection();
        const sessionId = req.params.sessionId;
        await connection.execute(
            `BEGIN SesionesPkg.eliminar_sesion(:sessionId); END;`,
            { sessionId: sessionId },
            { autoCommit: true }
        );
        res.status(204).send();  // No content to send back
    } catch (error) {
        res.status(500).send(`Error al eliminar la sesión: ${error.message}`);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (error) {
                console.error('Error al cerrar la conexión a Oracle', error);
            }
        }
    }
});

module.exports = router;
