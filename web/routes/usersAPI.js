'use strict';

// Importación de módulos necesarios
const express = require('express');
const nodemailer = require('nodemailer');
const oracledb = require('oracledb');

// Creación del router de Express
const router = express.Router();

// Variables de entorno para la configuración
const emailDir = process.env.EMAIL_DIR;
const emailPass = process.env.EMAIL_PASS;

// Cliente de MongoDB

const peliculas = {
    'wicked': 'Wicked',
    'argylle': 'Argylle',
    'dune': 'Dune',
    'dune2': 'Dune: Parte 2',
    'kung_fu_panda_4': 'Kung Fu Panda 4',
    'one_love': 'One Love',
    'madame_web': 'Madame Web',
    'wonka': 'Wonka'
};

const menusDiccionario = {
    betterTogether: 'Menú Better Together',
    grande: 'Menú grande',
    mediano: 'Menú mediano',
    infantil: 'Menú pequeño'
};

// Configuración de la conexión de nodemailer con Gmail
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: emailDir,
        pass: emailPass
    }
});

// Middleware para parsear el cuerpo de las solicitudes a JSON
router.use(express.json());

function enviarBienvenidaHTML(user){
    return `
        <div style="width: 100%; display: flex; flex-wrap: wrap; align-items: flex-start; background-color: #f4f4f4; padding: 20px;">
            <div style="flex: 1; min-width: 50%; padding: 20px;">
                <h1><strong>¡Bienvenido a ElmoCines!</strong></h1>
                <h2>¡Hola ${user.name}!</h2>
                <h2>Estamos ElmoCionados 😉 de tenerte con nosotros.</h2>
            </div>
            <div style="flex: 1; min-width: 50%; padding: 20px; text-align: center;">
                <img src="https://i.imgur.com/iGb7x17.gif" alt="Bienvenido" style="max-width: 100%; height: auto;">
            </div>
        </div>
    `;
}

function reservaHTML(updateData) {
    const booking = updateData.bookings[updateData.bookings.length - 1];

    // ID sesión: movie-userid-datetime --> Date: 8 dígitos (YYYYMMDD) + Time: 4 dígitos (HHMM)
    console.log(booking.booking_id);

    // Seleccionar la película de la reserva a partir del ID de la reserva y su correspondiente en el diccionario
    let movie = booking.booking_id.split('-')[0];
    movie = peliculas[movie];
    console.log(movie);

    // Seleccionar la fecha a partir del ID de la reserva y formatearla a DD/MM/YYYY
    let date = booking.booking_id.split('-')[2];
    date = `${date.slice(6, 8)}/${date.slice(4, 6)}/${date.slice(0, 4)}`;
    console.log(date);

    // Seleccionar la hora a partir del ID de la reserva y formatearla a HH:MM
    let time = booking.booking_id.split('-')[2];
    time = `${time.slice(8, 10)}:${time.slice(10, 12)}`;
    console.log(time);

    // Formatear los menús a su correspondiente en el diccionario
    let menus = booking.menus.map(menuCode => {
        const menuKey = menuCode.split('-')[1];
        return menusDiccionario[menuKey];
    });
    if(menus.length === 0) menus.push('Ningún menú 🐀');

    return `
        <div style="width: 100%; display: flex; flex-wrap: wrap; align-items: flex-start; background-color: #f4f4f4; padding: 20px;">
            <div style="flex: 1; min-width: 50%; padding: 20px;">
                <h1><strong>¡Hola ${updateData.name}!</strong></h1>
                <p>Has realizado una reserva
                 para la película: <strong>${movie}</strong></p>
                <p><strong>Fecha:</strong> ${date}, <strong>Sesión:</strong> ${time}</p>
                <p><strong>Menús seleccionados:</strong> ${menus.join(', ')}</p>
                <p><strong>Total:</strong> ${booking.total} €</p>
                <h4><a href="https://worthy-initially-rhino.ngrok-free.app/html/confirmed.html">Confirma tu compra aquí</a></h4>
            </div>
            <div style="flex: 1; min-width: 50%; padding: 20px; text-align: center;">
                <img src="https://i.imgur.com/6XcVR6W.png" alt="Elmo Love" style="max-width: 100%; height: auto;">
            </div>
        </div>
    `;
}

// Función para enviar emails
async function sendEmail(to, subject, html) {
    const mailOptions = {
        from: 'ElmoCines',
        to,
        subject,
        html
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Email enviado a ${to}`);
    } catch (error) {
        console.error(`Error al enviar el email a ${to}:`, error);
    }
}

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
        const result = await connection.execute(
            `BEGIN :cursor := ClientesPkg.listar_clientes(); END;`,
            {
                cursor: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            }
        );
        const resultSet = result.outBinds.cursor;
        const rows = await resultSet.getRows(); // Fetch all rows

        const clients = rows.map((row) => ({
            Nombre: row[1], 
            Correo: row[0],
            Telefono: row[2]
        }));

        await resultSet.close();
        res.json(clients);
    } catch (error) {
        res.status(500).send('Error retrieving users: ' + error.message);
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
        const userId = req.params.id;
        connection = await openConnection();
        const result = await connection.execute(
            `BEGIN :cursor := ClientesPkg.listar_cliente(:id); END;`,
            {
                id: userId,
                cursor: { type: oracledb.CURSOR, dir: oracledb.BIND_OUT }
            }
        );
        const resultSet = result.outBinds.cursor;
        const rows = await resultSet.getRows(); // Fetch all rows
        
        await resultSet.close();
        if (rows.length > 0) {
            const client = {
                Correo: rows[0][0], // Asume que Correo está en la primera columna
                Nombre: rows[0][1], // Asume que Nombre está en la segunda columna
                Telefono: rows[0][2] // Asume que Telefono está en la tercera columna
            };
            res.json(client);
        } else {
            res.status(404).send('User not found');
        }
    } catch (error) {
        res.status(500).send('Error retrieving user: ' + error.message);
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
    try {
        const newUser = req.body;
        console.log(newUser);
        connection = await openConnection();
        await connection.execute(`EXECUTE ClientesPkg.InsertOrUpdateCliente(:email, :name, :phone)`, {
            email: newUser.email,
            name: newUser.name,
            phone: newUser.phone
        });
        await connection.commit();
        res.status(201).send('User added successfully');
    } catch (error) {
        res.status(500).send('Error adding user: ' + error.message);
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

router.put('/:id', async (req, res) => {
    let connection;
    try {
        const userId = req.params.id;
        const updateData = req.body;
        connection = await openConnection();

        // Usar BEGIN ... END; para envolver la llamada al procedimiento almacenado
        const sql = `BEGIN ClientesPkg.modificar_cliente(:email, :name, :phone); END;`;
        const binds = {
            email: userId,      // ID del usuario como correo
            name: updateData.name, // Nombre a actualizar
            phone: updateData.phone // Teléfono a actualizar
        };

        // Ejecución del procedimiento almacenado
        const result = await connection.execute(sql, binds, { autoCommit: true });

        // Oracle no actualiza rowsAffected en las llamadas a procedimientos, por eso no podemos usarlo para verificar
        res.send('User updated successfully');
        
    } catch (error) {
        console.error('Error updating user: ', error);
        res.status(500).send('Error updating user: ' + error.message);
    } finally {
        if (connection) {
            try {
                await connection.close(); // Asegurar que la conexión siempre se cierra
            } catch (err) {
                console.error('Error closing connection: ', err);
            }
        }
    }
});

router.delete('/:id', async (req, res) => {
    let connection;
    try {
        const userId = req.params.id;
        connection = await openConnection();
        
        // Utilizar una llamada de procedimiento adecuada en PL/SQL
        const result = await connection.execute(
            `BEGIN ClientesPkg.eliminar_cliente(:email); END;`, // Corregido para usar la sintaxis correcta de PL/SQL
            { email: userId },
            { autoCommit: false } // Desactivar autoCommit para manejarlo manualmente
        );

        // Oracle no usa `rowsAffected` directamente en este contexto para los procedimientos almacenados
        // Necesitamos confirmar que el procedimiento se ejecutó sin errores
        if (result) {
            await connection.commit(); // Asegurar que la transacción se cometa si no hay errores
            res.send('User deleted successfully');
        } else {
            await connection.rollback(); // Asegurar que la transacción se revierta si hay un fallo
            res.status(404).send('User not found');
        }
    } catch (error) {
        await connection.rollback(); // Revertir cualquier cambio si hay una excepción
        res.status(500).send('Error deleting user: ' + error.message);
        console.error('Error during deletion:', error);
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Error closing connection:', err);
            }
        }
    }
});


router.delete('/', async (req, res) => {
    let connection;
    try {
        connection = await openConnection();
        
        // Correcto uso del procedimiento almacenado dentro de un bloque BEGIN ... END;
        const sql = `BEGIN ClientesPkg.eliminar_todos_clientes(); END;`;
        await connection.execute(sql, {}, { autoCommit: true }); // AutoCommit puede ser útil aquí si deseas que la operación se confirme automáticamente

        res.send('All users deleted successfully');
    } catch (error) {
        console.error('Error deleting users: ', error);
        res.status(500).send('Error deleting users: ' + error.message);
        // Es buena práctica agregar aquí un rollback en caso de que autoCommit esté deshabilitado y la operación falle
        if (!connection.autoCommit) {
            await connection.rollback();
        }
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error('Error closing connection: ', err);
            }
        }
    }
});


module.exports = router;
