require('dotenv').config(); // Variables de entorno (MONGODB_KEY, DATABASE_NAME)

const http = require('http'); // Servidor HTTP
const express = require('express'); // Layer built on the top of the Node js that helps manage servers and routes
const morgan = require('morgan'); // Advanced logger for HTTP requests
const cors = require('cors'); // Authorized resource sharing with external third parties (bloquea peticiones HTTP de terceros)
const path = require('path'); // Path module provides utilities for working with file and directory paths

const app = express();
const port = process.env.PORT || 3000;
const billboard = require('./routes/billboardAPI');
const sessions = require('./routes/sessionsAPI');
const users = require('./routes/usersAPI');
const booking = require('./routes/bookingAPI');

app.use(express.json()); // Parsea los datos JSON y los almacena en req.body
app.use(express.urlencoded({ extended: true })); // Parsea los datos de la URL y los almacena en req.body
app.use(morgan('dev')); // Modo de logger dev: Muestra los mensajes de registro en la consola
app.use(cors()); // Permite que los recursos de la API sean solicitados por dominios diferentes

app.use(express.static(path.join(__dirname, 'public'))); 

app.use('/billboard', billboard);
app.use('/sessions', sessions);
app.use('/users', users);
app.use('/booking', booking);

const server = http.createServer(app);

server.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
