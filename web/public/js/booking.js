document.addEventListener('DOMContentLoaded', () => {
    const { movie, sesion, butacas } = obtenerParametrosURL();
    let butacasArray = butacas ? butacas.split(',') : [];

    // Si se han pasado los parámetros necesarios, se procede a cargar la información de la película y la sesión
    if (movie && sesion && butacas) {
        const fecha = formatearFecha(sesion);
        const hora = formatearHora(sesion);

        actualizarInfoSesion(fecha, hora, butacasArray);
        cargarInformacionPelicula(movie);

        // Verificar la disponibilidad de las butacas seleccionadas
        verificarButacasDisponibles(movie, sesion, butacasArray)
            .then(disponibles => {
                if (disponibles) {
                    generarDesplegableMenores(butacasArray.length);
                    generarDesplegablesMenus(butacasArray.length);
                    actualizarResumen();
                } else {
                    mensajeError('Alguna de las butacas seleccionadas ya ha sido reservada. \nInténtelo de nuevo :(');
                }
            })
            .catch(error => mensajeError('Ocurrió un error al verificar la disponibilidad de las butacas.', error));

        // Evento para el botón de reserva
        document.querySelector('.btn').addEventListener('click', (e) => {
            e.preventDefault();
            if (validarCorreo() && validarTelefono() && validarNombre()) { // Si los campos de texto son válidos
                // Se actualiza la información del usuario
                let correo = document.querySelector('#correo').value;
                let nombreCompleto = document.querySelector('#nombre').value;
                let telefono = document.querySelector('#telefono').value;
                let sesionv2 = sesion.split('-')[0] + '' + sesion.split('-')[1];
                let reservaId = `${movie}-${correo}-${sesionv2}`;

                const menusTexto = ['nada', 'betterTogether', 'grande', 'mediano', 'infantil'];
                let menusSeleccionados = [];
                for (let i = 1; i <= butacasArray.length; i++) {
                    let menu = document.querySelector(`#menu-${i}`).value;
                    if (menu > 0) {
                        menusSeleccionados.push(`entrada${i}-${menusTexto[menu]}`);
                    }
                }

                let entradasAdultos = butacasArray.length - document.querySelector('#menoresDesplegable').value;
                let entradasMenores = parseInt(document.querySelector('#menoresDesplegable').value);

                // Verificar de nuevo la disponibilidad de las butacas antes de realizar la reserva
                verificarButacasDisponibles(movie, sesion, butacas.split(','))
                    .then(disponibles => {
                        if (disponibles) {
                            actualizarUsuario(correo, nombreCompleto, telefono, reservaId, butacasArray, menusSeleccionados, entradasAdultos, entradasMenores)
                                .then(() => actualizarSesion(movie, sesion, butacasArray, correo))
                                .then(() => window.location.href = 'thankyou.html')
                                .catch(error => console.error('Error al actualizar usuario o sesión', error));
                        } else {
                            alert('Alguna de las butacas seleccionadas ya ha sido reservada.');
                        }
                    })
                    .catch(error => {
                        console.error(error);
                        alert('Ocurrió un error al verificar la disponibilidad de las butacas.');
                    });
            } else {
                alert('Por favor, corrija los datos introducidos :(');
            }
        });

        // Listeners para comprobar la validez de los campos de texto
        document.querySelector('#nombre').addEventListener('input', actualizarInfo);
        document.querySelector('#correo').addEventListener('input', actualizarInfo);
        document.querySelector('#telefono').addEventListener('input', actualizarInfo);
    } else {
        mensajeError('Error de parametrización. \nNo introduzca la URL manualmente >:(', 'URL introducida manualmente');
    }
});

// Funciones auxiliares
function actualizarUsuario(correo, nombreCompleto, telefono, reservaId, butacasArray, menusSeleccionados, entradasAdultos, entradasMenores) {
    return fetch(`/users/${correo}`)
        .then(response => {
            if (response.ok) return response.json();
            else throw new Error('Usuario no encontrado, se creará uno nuevo.');
        })
        .then(usuario => {
            usuario.n_bookings = usuario.n_bookings ? usuario.n_bookings + 1 : 1;
            usuario.bookings = usuario.bookings ? usuario.bookings : [];
            usuario.bookings.push({
                booking_id: reservaId,
                adults: entradasAdultos,
                children: entradasMenores,
                seats: butacasArray,
                menus: menusSeleccionados,
                total: parseInt(document.querySelector('#total').textContent.split(' ')[1])
            });
            return fetch(`/users/${correo}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(usuario)
            });
        })
        .catch(() => {
            let nuevoUsuario = {
                _id: correo,
                name: nombreCompleto,
                phone: telefono,
                n_bookings: 1,
                bookings: [{
                    booking_id: reservaId,
                    adults: entradasAdultos,
                    children: entradasMenores,
                    seats: butacasArray,
                    menus: menusSeleccionados,
                    total: parseInt(document.querySelector('#total').textContent.split(' ')[1])
                }]
            };
            return fetch(`/users`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(nuevoUsuario)
            });
        });
}

// Actualiza la sesión con las butacas ocupadas y el correo del usuario
function actualizarSesion(movie, sesion, butacasArray, correo) {
    return fetch(`/sessions/${movie}/${sesion}`)
        .then(response => response.json())
        .then(sesionData => {
            // Decrementa butacas_libres por el número de butacas a ocupar, teniendo en cuenta cuando es 0 se establezca 0 y no null
            sesionData.butacas_libres -= butacasArray.length;
            sesionData.butacas_detalles.forEach(butaca => {
                if (butacasArray.includes(butaca.numero)) {
                    butaca.estado = 'ocupado';
                    butaca.email = correo;
                }
            });
            // Incluye butacas_libres en el cuerpo de la solicitud PUT
            return fetch(`/sessions/${movie}/${sesion}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    butacas_libres: sesionData.butacas_libres, // Asegúrate de que este valor sea el correcto para tu servidor
                    butacas_detalles: sesionData.butacas_detalles
                })
            });
        });
}

// Obtiene los parámetros de la URL
function obtenerParametrosURL() {
    const urlParams = new URLSearchParams(window.location.search);
    return {
        movie: urlParams.get('movie'),
        sesion: urlParams.get('sesion'),
        butacas: urlParams.get('seats')
    };
}

// Formatea la fecha y la hora de la sesión
function formatearFecha(sesion) {
    const fecha = sesion.split('-')[0];
    return `${fecha.substring(0, 4)}-${fecha.substring(4, 6)}-${fecha.substring(6, 8)}`;
}

// Formatea la hora de la sesión
function formatearHora(sesion) {
    const hora = sesion.split('-')[1];
    return `${hora.substring(0, 2)}:${hora.substring(2, 4)}`;
}

// Actualiza la información de la sesión en la página
function actualizarInfoSesion(fecha, hora, butacasArray) {
    document.querySelector('#fecha').textContent = fecha;
    document.querySelector('#sesion').textContent = hora;
    document.querySelector('#butacas').textContent = '[' + butacasArray.length + '] ' + butacasArray.join(', ');
}

// Carga la información de la película en la página
function cargarInformacionPelicula(movie) {
    fetch(`/billboard/${movie}`)
        .then(response => response.json())
        .then(data => {
            document.querySelector('.titulo-seccion').textContent = 'RESERVA DE ENTRADAS: ' + data.title;
        })
        .catch(error => mensajeError('Error al cargar la información de la sesión', error));
}

// Verifica la disponibilidad de las butacas seleccionadas
function verificarButacasDisponibles(movie, sesion, butacasArray) {
    return fetch(`/sessions/${movie}/${sesion}`)
        .then(response => response.json())
        .then(data => butacasArray.every(butaca => data.butacas_detalles.some(b => b.numero === butaca && b.estado === 'libre')))
        .catch(error => {
            mensajeError('Error al cargar la información de la sesión', error);
            throw error;
        });
}

// Muestra un mensaje de error en la página
function mensajeError(msj, error) {
    console.error(error);
    document.querySelector('.containerbody').innerHTML = `<div class="row d-flex justify-content-center align-items-center h-100 text-center"><h1>${msj.replace('\n', '<br>')}</h1></div>`;
}

// Funciones para la reserva
function generarDesplegableMenores(numeroButacas) {
    const contenedor = document.querySelector('.field.age');
    let select = document.createElement('select');
    select.className = 'form-control';
    select.id = 'menoresDesplegable';

    for (let i = 0; i <= numeroButacas; i++) {
        let option = document.createElement('option');
        option.value = i;
        option.textContent = i;
        select.appendChild(option);
    }

    contenedor.appendChild(select);
    select.addEventListener('change', actualizarResumen);
    actualizarResumen();
}

// Genera los desplegables de menús para cada butaca
function generarDesplegablesMenus(numeroButacas) {
    const form = document.querySelector('.datos-compra');
    for (let i = 1; i <= numeroButacas; i++) {
        let div = document.createElement('div');
        div.className = 'field';
        let h4 = document.createElement('h4');
        h4.textContent = `Entrada ${i}: Menú`;
        let select = document.createElement('select');
        select.className = 'form-control menu-select';
        select.id = `menu-${i}`;

        ['Sin menú', 'Menú Better Together (10 €)', 'Menú grande (8 €)', 'Menú mediano (6 €)', 'Menú infantil (4 €)'].forEach((opcion, index) => {
            let option = document.createElement('option');
            option.value = index;
            option.textContent = opcion;
            select.appendChild(option);
        });

        div.appendChild(h4);
        div.appendChild(select);
        form.appendChild(div);

        select.addEventListener('change', actualizarResumen);
    }
    actualizarResumen();
}

// Actualiza el resumen de la compra
function actualizarResumen() {
    const numeroButacas = document.querySelector('#butacas').textContent.split(']')[0].replace('[', '');
    const numeroMenores = document.querySelector('#menoresDesplegable') ? document.querySelector('#menoresDesplegable').value : 0;
    const menusSeleccionados = document.querySelectorAll('.menu-select');
    let total = 0;
    let resumenHTML = '';
    if(numeroMenores < numeroButacas){
        resumenHTML += `<p>${numeroButacas - numeroMenores}x - Entradas adultas (6 €)</p>`;
    }
    if (numeroMenores > 0) {
        resumenHTML += `<p>${numeroMenores}x - Entradas menores (4 €)</p>`;
    }
    menusSeleccionados.forEach((menu, index) => {
        let valorMenu = parseInt(menu.value);
        if (valorMenu > 0) {
            let textoMenu = menu.options[menu.selectedIndex].text;
            let precioMenu = textoMenu.match(/\(([^)]+)\)/)[1];
            resumenHTML += `<p>Entrada ${index + 1}: ${textoMenu}</p>`;
            total += parseInt(precioMenu.split(' ')[0]);
        }
    });
    total += (numeroButacas - numeroMenores) * 6 + numeroMenores * 4;
    resumenHTML += `<p class = 'pt-2' id = 'total'>Total: ${total} €</p>`;

    document.querySelector('.resumenCol').innerHTML = resumenHTML;
}

// Actualiza la información del usuario
function actualizarInfo(){
    let informacion = '';
    if(validarNombre()){
        informacion += `<p><strong>Nombre:</strong> ${document.querySelector('#nombre').value}</p>`;
    }
    if(validarCorreo()){
        informacion += `<p><strong>Correo:</strong> ${document.querySelector('#correo').value}</p>`;
    }
    if(validarTelefono()){
        informacion += `<p><strong>Teléfono:</strong> ${document.querySelector('#telefono').value}</p>`;
    }
    document.querySelector('.infoCol').innerHTML = informacion;
}

// Validación de los campos de texto
function mostrarErrorValidacion(selector, mensaje) {
    let elemento = document.querySelector(selector);
    let error = document.createElement('div');
    error.classList.add('error');
    error.textContent = mensaje;
    // Usar nextElementSibling en lugar de nextSibling
    if (!elemento.nextElementSibling || !elemento.nextElementSibling.classList.contains('error')) {
        elemento.parentNode.insertBefore(error, elemento.nextElementSibling);
    }
}

// Elimina el mensaje de error de validación
function eliminarErrorValidacion(selector) {
    let elemento = document.querySelector(selector);
    // Usar nextElementSibling en lugar de nextSibling
    if (elemento.nextElementSibling && elemento.nextElementSibling.classList.contains('error')) {
        elemento.parentNode.removeChild(elemento.nextElementSibling);
    }
}

// Validación de los campos de texto
function validarNombre() {
    let nombre = document.querySelector('#nombre').value;
    if (!nombre.match(/^[A-Z][a-z]+\s[A-Z][a-z]+$/)) {
        mostrarErrorValidacion('#nombre', 'El nombre debe contener, exactamente, un nombre y un apellido, ambos empezando por mayúscula, sin números y sin tildes.');
        return false;
    } else {
        eliminarErrorValidacion('#nombre');
        return true;
    }
}

// Validación de los campos de texto
function validarCorreo() {
    let email = document.querySelector('#correo').value;
    if (!email.match(/^[^@\s]+@[^@\s]+\.(com|es)(\/\S*)?$/)) {
        mostrarErrorValidacion('#correo', 'El correo debe tener el formato correo@dominio.com/es');
        return false;
    } else {
        eliminarErrorValidacion('#correo');
        return true;
    }
}

// Validación de los campos de texto
function validarTelefono() {
    let telefono = document.querySelector('#telefono').value;
    if (!telefono.match(/^[6789]\d{8}$/)) {
        mostrarErrorValidacion('#telefono', 'El número de teléfono debe empezar por 6, 7, 8 o 9 y contener 9 dígitos.');
        return false;
    } else {
        eliminarErrorValidacion('#telefono');
        return true;
    }
}