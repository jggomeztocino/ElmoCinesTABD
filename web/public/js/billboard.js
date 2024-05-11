// Crea una nueva columna en la fila especificada y le asigna una clase basada en el número de columna
function newColumn(rowID, nColumna) {
    const row = document.querySelector('#' + rowID);

    const column = document.createElement('div');
    const columClass = 'column' + nColumna;
    column.classList.add(columClass);
    row.appendChild(column);
    return columClass;
}

// Crea un nuevo elemento de película y lo añade al DOM bajo el elemento con ID 'billboard'
function newMovie(movie) {
    const billboard = document.querySelector("#billboard");
    const column = document.createElement('div');
    column.classList.add('col-md-6');
    column.classList.add('col-sm-6');
    column.classList.add('col-lg-3');
    column.classList.add('col-12');
    billboard.appendChild(column);

    const movieDiv = document.createElement('div');
    movieDiv.classList.add('movie');

    const movieTitle = document.createElement('h3');
    movieTitle.textContent = movie.titulo;
    movieDiv.appendChild(movieTitle);

    column.appendChild(movieDiv);

    const imgDiv = document.createElement('div');
    imgDiv.classList.add('imgDiv');
    imgDiv.classList.add('mb-3');
    movieDiv.appendChild(imgDiv);

    const movieLink = document.createElement('a');
    movieLink.href = `movie.html?movie=${movie.idPelicula}`;
    imgDiv.appendChild(movieLink);

    const movieCover = document.createElement('img');
    movieCover.classList.add('img-fluid');
    movieCover.classList.add('imgCover');
    movieCover.src = movie.urlCover; 
    movieCover.alt = movie.titulo;
    movieLink.appendChild(movieCover);
}

// Carga el contenido de la cartelera de películas desde la base de datos y lo muestra en el DOM
function loadBillboard() {
    fetch('/billboard')
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(movies => {
            movies.forEach(movie => {
                newMovie(movie);
            });
        })
        .catch(error => {
            mensajeError('Error al cargar la cartelera: ' + error.message);
        });
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

// Carga la cartelera una vez que el DOM esté completamente cargado
document.addEventListener('DOMContentLoaded', function() {
    loadBillboard();
});
