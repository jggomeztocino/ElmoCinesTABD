'use strict';

// Importación de módulos necesarios
const express = require('express');
const nodemailer = require('nodemailer');
const oracledb = require('oracledb');

// Creación del router de Express
const router = express.Router();

// Variables de entorno para la configuración

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
/*const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: emailDir,
        pass: emailPass
    }
});*/

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

// Ruta GET para obtener todos los usuarios
router.get('/', async (req, res) => {
    try {
        await client.connect();
        const db = client.db(dbName);
        const users = await db.collection('users').find({}).toArray();
        res.json(users);
    } catch (error) {
        res.status(500).send('Error al obtener los usuarios: ' + error.message);
    } finally {
        await client.close();
    }
});

// Ruta GET para obtener un usuario por ID
router.get('/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        await client.connect();
        const db = client.db(dbName);
        const user = await db.collection('users').findOne({ _id: userId });
        if (user) {
            res.json(user);
        } else {
            res.status(404).send('Usuario no encontrado');
        }
    } catch (error) {
        res.status(500).send('Error al obtener el usuario: ' + error.message);
    } finally {
        await client.close();
    }
});

// Ruta POST para añadir un nuevo usuario
router.post('/', async (req, res) => {
    try {
        const newUser = req.body;
        await client.connect();
        const db = client.db(dbName);
        const result = await db.collection('users').insertOne(newUser);
        if (result.acknowledged) {
            await sendEmail(newUser._id, '¡Bienvenido a ElmoCines!', enviarBienvenidaHTML(newUser));
            await sendEmail(newUser._id, '¡Aquí tienes tus entradas! ElmoCines', reservaHTML(newUser));
        }
        res.status(201).send('Usuario añadido correctamente');
    } catch (error) {
        res.status(500).send('Error al añadir el usuario: ' + error.message);
    } finally {
        await client.close();
    }
});

// Ruta PUT para actualizar un usuario
router.put('/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        const updateData = req.body;
        await client.connect();
        const db = client.db(dbName);
        const result = await db.collection('users').updateOne({ _id: userId }, { $set: updateData });

        if (result.matchedCount === 0) {
            res.status(404).send('Usuario no encontrado');
        } else {
            await sendEmail(userId, '¡Aquí tienes tus entradas! ElmoCines', reservaHTML(updateData));
            res.send('Usuario actualizado correctamente');
        }
    } catch (error) {
        res.status(500).send('Error al actualizar el usuario: ' + error.message);
    } finally {
        await client.close();
    }
});

// Ruta DELETE para eliminar un usuario por ID
router.delete('/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        await client.connect();
        const db = client.db(dbName);
        const result = await db.collection('users').deleteOne({ _id: userId });
        if (result.deletedCount === 0) {
            res.status(404).send('Usuario no encontrado');
        } else {
            res.send('Usuario eliminado correctamente');
        }
    } catch (error) {
        res.status(500).send('Error al eliminar el usuario: ' + error.message);
    } finally {
        await client.close();
    }
});

// Ruta DELETE para eliminar todos los usuarios
router.delete('/', async (req, res) => {
    try {
        await client.connect();
        const db = client.db(dbName);
        const result = await db.collection('users').deleteMany({});
        if (result.deletedCount === 0) {
            res.status(404).send('No se encontraron usuarios para eliminar.');
        } else {
            res.send(`Usuarios eliminados correctamente. Total: ${result.deletedCount}`);
        }
    } catch (error) {
        res.status(500).send('Error al eliminar los usuarios: ' + error.message);
    } finally {
        await client.close();
    }
});

module.exports = router;
