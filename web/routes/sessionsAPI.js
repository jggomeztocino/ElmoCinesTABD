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

        // Obtener sesiones con butacas libres
        const result = await connection.execute(
            `BEGIN :ret := SesionesPkg.sesiones_con_butacas_libres(:movieId); END;`,
            {
                movieId: movieId,
                ret: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );
        
        const resultSet = result.outBinds.ret;
        const sessions = [];

        // Leer resultados y construir sesiones
        let row;
        while ((row = await resultSet.getRow())) {
            const sessionDetail = {
                idSesion: row[0],
                FechaHora: row[1],
                NumeroSala: row[2],
                ButacasLibres: row[3],
                butacas_detalles: []
            };

            // Obtener detalles de butacas ocupadas
            const occupiedSeats = await connection.execute(
                `BEGIN :ret := SesionesPkg.butacas_ocupadas(:idSesion); END;`,
                {
                    idSesion: sessionDetail.idSesion,
                    ret: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
                }
            );

            const occupiedSet = occupiedSeats.outBinds.ret;
            let seat;
            while ((seat = await occupiedSet.getRow())) {
                // Conversión de idButaca a formato A1, A2, ..., F5
                let row = String.fromCharCode(65 + Math.floor((seat[0] - 1) / 5));
                let column = ((seat[0] - 1) % 5) + 1;
                sessionDetail.butacas_detalles.push({
                    numero: `${row}${column}`,
                    estado: 'ocupado'
                });
            }
            await occupiedSet.close();

            // Agregar detalles para butacas libres
            for (let i = 1; i <= 30; i++) {
                let row = String.fromCharCode(65 + Math.floor((i - 1) / 5));
                let column = ((i - 1) % 5) + 1;
                let seatNumber = `${row}${column}`;
                if (!sessionDetail.butacas_detalles.some(seat => seat.numero === seatNumber)) {
                    sessionDetail.butacas_detalles.push({
                        numero: seatNumber,
                        estado: 'libre'
                    });
                }
            }

            sessions.push(sessionDetail);
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

router.get('/:movieId/:idPelicula/:FechaHora', async (req, res) => {
    // Obtener el idSesion mediante el idPelicula y la FechaHora
    let connection;
    try {
        connection = await openConnection();
        const idPelicula = req.params.idPelicula;
        const FechaHora = req.params.FechaHora;
        const result = await connection.execute(
            `SELECT idSesion
            FROM Sesiones
            WHERE idPelicula = :idPelicula AND FechaHora = :FechaHora`,
            [idPelicula, FechaHora]
        );

        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.status(404).send('Sesión no encontrada');
        }
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

router.get('/id/:idReserva', async (req, res) => {
        let connection;
    try {
        connection = await openConnection();
        const idReserva = req.params.idReserva;
        const result = await connection.execute(
            `SELECT idSesion
            FROM ButacasReservas br
            JOIN Reservas r ON br.idReserva = r.idReserva
            WHERE br.idButaca = :idReserva`,
            [idReserva]
        );

        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.status(404).send('Reserva no encontrada');
        }
    } catch (error) {
        res.status(500).send(`Error al obtener la reserva: ${error.message}`);
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
