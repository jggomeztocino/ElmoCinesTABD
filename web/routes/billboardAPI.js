'use strict';

const express = require('express');
const router = express.Router();
const oracledb = require('oracledb');

// Middleware para convertir el cuerpo de las solicitudes a JSON
router.use(express.json());

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



// Obtener todas las películas
router.get('/', async (req, res) => {
    let connection;
    try {
        connection = await openConnection();
        // Realizar la llamada a la función que retorna un SYS_REFCURSOR
        const result = await connection.execute(
            `BEGIN :ret := PeliculasPkg.listar_peliculas(); END;`, 
            { ret: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR } }
        );

        const resultSet = result.outBinds.ret;
        const movies = [];

        let row;
        while ((row = await resultSet.getRow())) {
            movies.push({
                idPelicula: row[0],
                titulo: row[1],
                urlCover: row[2]
            });
        }

        await resultSet.close();

        res.json(movies);
    } catch (error) {
        res.status(500).send('Error al obtener las películas: ' + error.message);
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


router.get('/:id', async (req, res) => {
    let connection;
    try {
        const movieId = req.params.id;
        connection = await openConnection();
        const result = await connection.execute(
            `BEGIN :ret := PeliculasPkg.listar_pelicula(:id); END;`,
            {
                id: movieId,
                ret: { dir: oracledb.BIND_OUT, type: oracledb.CURSOR }
            }
        );

        const resultSet = result.outBinds.ret;
        const row = await resultSet.getRow();
        if (row) {
            const movie = {
                idPelicula: row[0],
                titulo: row[1],
                directores: row[2],
                actores: row[3],
                duracion: row[4],
                sinopsis: row[5],
                urlCover: row[6],
                urlTrailer: row[7]
            };
            res.json(movie);
        } else {
            res.status(404).send('Película no encontrada');
        }

        await resultSet.close();
    } catch (error) {
        res.status(500).send('Error al obtener la película: ' + error.message);
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


router.delete('/:id', async (req, res) => {
    let connection;
    try {
        const movieId = req.params.id;
        connection = await openConnection();
        await connection.execute(
            `BEGIN PeliculasPkg.eliminar_pelicula(:id); END;`,
            { id: movieId },
            { autoCommit: true }
        );
        res.send('Película eliminada correctamente');
    } catch (error) {
        if (error.message.includes('ORA-02292')) {
            res.status(409).send('No se puede eliminar la película porque tiene dependencias');
        } else {
            res.status(500).send('Error al eliminar la película: ' + error.message);
        }
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
