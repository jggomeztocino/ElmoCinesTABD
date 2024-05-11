// Se activa una vez el DOM está completamente cargado.
document.addEventListener('DOMContentLoaded', function() {
    const urlParams = new URLSearchParams(window.location.search);
    const movie = urlParams.get('movie');
    let fecha;
    let sesion;
    const today = new Date().toISOString().split('T')[0];
    let butacasSeleccionadas = [];

    if (movie) {
        // Solicitud fetch para obtener la información de la película.
        fetch(`/billboard/${movie}`)
            .then(response => response.json())
            .then(data => {
                // Actualiza el contenido de la página con el título de la película
                document.querySelector('.movieTitle').textContent = data.titulo;
            })
            .catch(error => {
                mensajeError('Error al cargar la información de la película: ' + error.message);
            });
        // Llama a la función para cargar las fechas de las sesiones disponibles para la película
        loadSessionDates(movie);
    } else {
        mensajeError('Error de parametrización. \nNo introduzca la URL manualmente >:(');
    }

    // Función para cargar y mostrar las fechas de las sesiones disponibles para la película seleccionada
    function loadSessionDates(movie) {
        fetch(`/sessions/${movie}`)
            .then(response => {
                if (!response.ok) {
                    throw new Error('Respuesta de red no fue ok');
                }
                return response.json();
            })
            .then(sesiones => {
                const fechas = sesiones.map(sesion => new Date(sesion.fechaHora).toISOString().split('T')[0]);
    
                if (fechas.length === 0) {
                    mensajeError('No hay sesiones disponibles para la película seleccionada.');
                    return;
                }
    
                const formulario = document.querySelector('.formulario');
                formulario.innerHTML = ''; // Limpiamos el formulario
    
                // Selector de fecha
                const tituloFecha = document.createElement('h4');
                tituloFecha.textContent = 'Fecha de la sesión:';
                formulario.appendChild(tituloFecha);
    
                const selectorFecha = document.createElement('select');
                selectorFecha.style.marginBottom = '20px';
                selectorFecha.classList.add('form-select');
                formulario.appendChild(selectorFecha);
    
                // Usamos un Set para eliminar fechas duplicadas
                [...new Set(fechas)].forEach(fecha => {
                    const option = document.createElement('option');
                    option.value = fecha;
                    option.textContent = fecha; // Formatear fecha para mostrarla de manera amigable si necesario
                    selectorFecha.appendChild(option);
                });
    
                selectorFecha.addEventListener('change', (event) => {
                    const fechaSeleccionada = event.target.value;
                    loadSessionTimes(movie, fechaSeleccionada, sesiones);
                });
    
                // Carga las horas de las sesiones para la primera fecha disponible
                loadSessionTimes(movie, fechas[0], sesiones);
            })
            .catch(error => {
                mensajeError('Error al cargar las fechas de las sesiones: ' + error.message);
            });
    }
    

    // Función para cargar y mostrar las horas disponibles para las sesiones de una fecha seleccionada.
    // Función para cargar y mostrar las horas disponibles para las sesiones de una fecha seleccionada.
    function loadSessionTimes(movie, fechaSeleccionada, sesiones) {
        const formulario = document.querySelector('.formulario');
        if (!formulario) {
            console.error('El elemento del formulario no existe en el DOM');
            return;
        }
    
        const sesionesDelDia = sesiones.filter(sesion => new Date(sesion.fechaHora).toISOString().split('T')[0] === fechaSeleccionada);
        
        // Limpia previamente cualquier selector de hora existente
        const selectorPrevio = document.querySelector('.selectorHora');
        const tituloPrevio = document.querySelector('.tituloHora');
        if (selectorPrevio) selectorPrevio.remove();
        if (tituloPrevio) tituloPrevio.remove();
    
        // Crea un nuevo título y selector para la hora de la sesión
        const tituloHora = document.createElement('h4');
        tituloHora.textContent = 'Hora de la sesión:';
        tituloHora.classList.add('tituloHora');
        formulario.appendChild(tituloHora);
    
        const selectorHora = document.createElement('select');
        selectorHora.style.marginBottom = '20px';
        selectorHora.classList.add('form-select', 'selectorHora');
        formulario.appendChild(selectorHora);
    
        sesionesDelDia.forEach(sesion => {
            const hora = new Date(sesion.fechaHora).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
            if (sesion.butacasLibres > 0) {
                const option = document.createElement('option');
                option.value = sesion.fechaHora;
                option.textContent = hora;
                selectorHora.appendChild(option);
            }
        });
    
        selectorHora.addEventListener('change', (event) => {
            const fechaHoraSeleccionada = event.target.value;
            const sesionSeleccionada = sesiones.find(sesion => sesion.fechaHora === fechaHoraSeleccionada);
            if (sesionSeleccionada && sesionSeleccionada.butacasDetalles) {
                mostrarMapaDeAsientos(sesionSeleccionada.butacasDetalles);
            }
        });
    
        // Carga automáticamente los detalles de la primera sesión disponible
        if (sesionesDelDia.length > 0 && sesionesDelDia[0].butacasDetalles) {
            mostrarMapaDeAsientos(sesionesDelDia[0].butacasDetalles);
        } else {
            formulario.append('No hay sesiones disponibles a esta hora.');
        }
    }
    

// Esta función asume que la estructura de datos incluye `butacasDetalles` que es un array de detalles de las butacas.
// Asegúrate de adaptar esta parte a cómo realmente recibes y quieres procesar los datos de las butacas.


    // Función para mostrar el mapa de asientos y gestionar la selección de asientos por el usuario
    function mostrarMapaDeAsientos(butacas) {
        butacasSeleccionadas = []; // Reinicia las butacas seleccionadas al cambiar de sesión
        actualizarButacasSeleccionadas(); // Actualiza visualmente las butacas seleccionadas

        const mapaButacas = document.querySelector('.mapaButacas');
        mapaButacas.innerHTML = '<div class="pantalla">PANTALLA</div>';
        mapaButacas.style.margin = '20px 0';
        mapaButacas.style.paddingBottom = '10px';

        for (let i = 0; i < 6; i++) {
            const fila = document.createElement('div');
            fila.style.display = 'flex';
            fila.style.justifyContent = 'center';

            for (let j = 0; j < 5; j++) {
                const index = i * 5 + j;
                if (index < butacas.length) {
                    const asiento = document.createElement('div');
                    asiento.className = `asiento ${butacas[index].estado}`;
                    asiento.textContent = butacas[index].numero;
                    asiento.onclick = () => seleccionarAsiento(asiento, butacas[index]);
                    fila.appendChild(asiento);
                }
            }
            mapaButacas.appendChild(fila);
        }

        // Leyenda de colores para los asientos
        const leyenda = document.createElement('div');
        leyenda.className = 'leyenda';
        leyenda.style.color = 'black';
        leyenda.innerHTML = `
            <div><div class="color" style="background-color: var(--color-auxiliar);"></div>Libre</div>
            <div><div class="color" style="background-color: var(--color-terciario);"></div>Ocupado</div>
            <div><div class="color" style="background-color: var(--color-seleccionado);"></div>Seleccionado</div>
        `;
        mapaButacas.appendChild(leyenda);
    }

    // Función para manejar la selección de asientos
    function seleccionarAsiento(asiento, butaca) {
        if (butaca.estado !== 'ocupado') {
            if (butaca.estado === 'libre') {
                if (butacasSeleccionadas.length >= 5) {
                    alert('No se pueden seleccionar más de 5 butacas.');
                    return; // No permitir más selecciones si ya hay 5 butacas seleccionadas
                }
                butacasSeleccionadas.push(butaca.numero);
            } else if (butaca.estado === 'seleccionado') {
                butacasSeleccionadas = butacasSeleccionadas.filter(num => num !== butaca.numero);
            }

            // Cambiar el estado de la butaca y actualizar la clase CSS
            butaca.estado = butaca.estado === 'seleccionado' ? 'libre' : 'seleccionado';
            asiento.className = `asiento ${butaca.estado}`;

            // Actualizar visualmente la lista de butacas seleccionadas
            actualizarButacasSeleccionadas();
        }
    }

    // Función para actualizar la visualización de las butacas seleccionadas
    function actualizarButacasSeleccionadas() {
        let contenedor = document.querySelector('.butacasSeleccionadas');
        if (!contenedor) {
            contenedor = document.createElement('div');
            contenedor.classList.add('butacasSeleccionadas');
            document.querySelector('.formulario').appendChild(contenedor);
        }

        contenedor.innerHTML = `<h4>Butacas seleccionadas:</h4>
                                <p>[${butacasSeleccionadas.length}] ${butacasSeleccionadas.join(', ')}</p>`;

        // Revisa si ya existe un mensaje de revisión y el botón continuar
        let continuarCompra = document.querySelector('.continuarCompra');
        let btn = document.querySelector('.btn');

        // Si hay al menos una butaca seleccionada y no existe el mensaje ni el botón, los crea
        if (butacasSeleccionadas.length > 0) {
            if (!continuarCompra) {
                continuarCompra = document.createElement('h4');
                continuarCompra.classList.add('continuarCompra');
                continuarCompra.classList.add('text-center');
                continuarCompra.textContent = 'Revisa los datos antes de seguir con la compra';
                document.querySelector('.formulario').appendChild(continuarCompra);
            }

            if (!btn) {
                btn = document.createElement('button');
                btn.classList.add('btn');
                btn.textContent = 'Continuar';
                btn.style.marginTop = '10px';
                btn.onclick = function() {
                    // Redirige a la página de compra con las butacas seleccionadas (para el siguiente hito, integrar con API)
                    window.location.href = 'booking.html?movie=' + movie + '&sesion=' + sesion + '&seats=' + butacasSeleccionadas.join(',');
                };
                document.querySelector('.formulario').appendChild(btn);
            }
        } else {
            // Si no hay butacas seleccionadas y existen el mensaje o el botón, los elimina
            continuarCompra?.remove();
            btn?.remove();
        }
    }

    // Función para mostrar mensaje de error en consola y en el DOM
    function mensajeError(msj){
        console.error(msj);

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
});