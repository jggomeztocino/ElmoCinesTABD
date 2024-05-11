// Se activa una vez el DOM está completamente cargado.
document.addEventListener('DOMContentLoaded', function() {
    // Obtiene el parámetro 'movie' de la URL.
    const urlParams = new URLSearchParams(window.location.search);
    const movie = urlParams.get('movie'); // Obtiene el parámetro 'movie' de la URL

    if (movie) {
        // Si hay un parámetro 'movie', carga la información y las fechas de sesión de la película.
        loadMovieInfo(movie);
        loadSessionDates(movie).then(() => console.log('Sesiones cargadas')); 
        // Añade un event listener al botón de entradas para redirigir al usuario a la pre-reserva con el parámetro de la película.
        document.getElementById('btnEntradas').addEventListener('click', function() {
            window.location.href = "pre-booking.html?movie=" + movie;
        });
    } else {
        mensajeError('Error de parametrización. \nNo introduzca la URL manualmente >:(');
    }
});

// Función para cargar la información de la película seleccionada
function loadMovieInfo(movie) {
    fetch('/billboard/' + movie)
        .then(response => response.json())
        .then(data => {
            // Rellena el contenido de la página con la información de la película
            document.querySelector('.caratula img').src = data.urlCover;
            document.querySelector('.info h3').textContent = data.titulo;
            document.querySelector('.info h5').nextElementSibling.textContent = data.directores;
            document.querySelector('.info h5:nth-of-type(2)').nextElementSibling.textContent = data.actores;
            document.querySelector('.info h5:nth-of-type(3)').nextElementSibling.textContent = `${data.duracion} min`;
            document.querySelector('.info h5:nth-of-type(4)').nextElementSibling.textContent = data.sinopsis;
            document.querySelector('.reproductor iframe').src = data.urlTrailer;
        })
        .catch(error => {
            mensajeError('Error al cargar la información de la película', error);
        });
}

async function loadSessionDates(movieId) {
    try {
        const response = await fetch(`/sessions/${movieId}`);
        if (!response.ok) {
            throw new Error('Respuesta de red no fue ok');
        }
        const sesiones = await response.json();

        // Extraer las fechas de las sesiones y usarlas para configurar el selector de fechas
        const fechas = sesiones.map(sesion => new Date(sesion.fechaHora).toISOString().split('T')[0]);
        const fechasUnicas = [...new Set(fechas)]; // Eliminar duplicados para obtener solo fechas únicas

        if (fechasUnicas.length === 0) {
            document.getElementById('labelFechas').style.display = 'none';
            document.getElementById('selectorFecha').style.display = 'none';
            document.getElementById('bloqueEntradas').style.display = 'none';

            const mensajeNoDisponible = document.createElement('div');
            mensajeNoDisponible.innerHTML = "<h2 id='noticket' style='margin-top: 30px'>No quedan entradas para esta película... :(</h2>";
            mensajeNoDisponible.className = "text-center";
            document.getElementById('sesiones').appendChild(mensajeNoDisponible);
            return;
        }

        // Configurar el selector de fechas con Flatpickr
        const hoy = new Date().toISOString().split('T')[0];
        const defaultDate = fechasUnicas.find(fecha => fecha >= hoy) || hoy;

        flatpickr("#selectorFecha", {
            dateFormat: "Y-m-d",
            minDate: hoy,
            maxDate: fechasUnicas[fechasUnicas.length - 1],
            defaultDate: defaultDate,
            enable: fechasUnicas,
            altInput: true,
            altFormat: "J \\de F \\de Y",
            locale: {
                firstDayOfWeek: 1, // Asegúrate de que los settings locales están correctamente configurados
                weekdays: {
                    shorthand: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'],
                    longhand: ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'],
                },
                months: {
                    shorthand: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
                    longhand: ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'],
                },
                ordinal: () => "" // Sufijo para el día del mes
            }
        });

        // Mostrar sesiones por fecha seleccionada
        document.getElementById('selectorFecha').addEventListener('change', function() {
            const fechaSeleccionada = this.value;
            mostrarSesionesPorFecha(sesiones.filter(sesion => new Date(sesion.fechaHora).toISOString().split('T')[0] === fechaSeleccionada));
        });

        mostrarSesionesPorFecha(sesiones.filter(sesion => new Date(sesion.fechaHora).toISOString().split('T')[0] === defaultDate));
    } catch (error) {
        mensajeError('Error al cargar las sesiones', error);
    }
}


function mostrarSesionesPorFecha(sesionesFiltradas) {
    const contenedorSesiones = document.getElementById('sesionesPelicula');
    contenedorSesiones.innerHTML = '';

    if (sesionesFiltradas.length > 0) {
        sesionesFiltradas.forEach(sesion => {
            const fechaHora = new Date(sesion.fechaHora);
            const hora = `${fechaHora.getHours()}:${fechaHora.getMinutes()}`;
            const div = document.createElement('div');
            div.innerHTML = `
                <p><strong>Hora:</strong> ${hora}</p>
                <p><strong>Sala:</strong> ${sesion.sala}</p>
                <p><strong>Butacas restantes:</strong> ${sesion.butacasLibres}</p>
            `;
            contenedorSesiones.appendChild(div);
        });
    } else {
        contenedorSesiones.innerHTML = '<p>No hay sesiones disponibles para esta fecha.</p>';
    }
}

// Función para mostrar mensaje de error en consola y en el DOM
function mensajeError(msj, error){
    console.error(error);

    const container = document.querySelector('.containerbody');
    container.innerHTML = '';
    container.classList.add('d-flex', 'justify-content-center', 'align-items-center', 'h-100');

    const row = document.createElement('div');
    row.classList.add('row');
    row.classList.add('d-flex', 'justify-content-center', 'align-items-center', 'h-100', 'text-center');
    container.appendChild(row);

    let mensajes = msj.split('\n');
    mensajes.forEach(mensaje => {
        const h = document.createElement('h1');
        h.textContent = mensaje;
        row.appendChild(h);
    });
}