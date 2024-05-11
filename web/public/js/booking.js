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

                let nuevoUsuario = {
                    correo: correo,
                    nombre: nombreCompleto,
                    telefono: telefono,
                }

                // 1. Invocar la función verificarButacasDisponibles
                // 1. Insertar Cliente con InsertOrUpdateCliente(Correo, Nombre, Telefono)
                // 2. Insertar Reserva con ReservasPkg.realizar_reserva(Sesion, Sala, Correo, Nombre, Telefono, Entradas, Butacas)
                // 2.1. Entradas a su vez es una estructura, con atributos idEntrada, idMenu, Descripcion y Precio
                // Nota: Los menús se enumeran del 0 al 4, siendo 0 el menú sin seleccionar
                // Por tanto, debe estructurarse de la siguiente manera, adaptándose a Oracle:
                // TipoEntradaArray(TipoEntrada(secuencia_idEntrada.NEXTVAL, 0, 'Entrada adulta', 6), TipoEntrada(secuencia_idEntrada.NEXTVAL, 1, 'Entrada infantil', 4), ...)
                // Con tantos TipoEntrada como entradas haya
                // 2.2. Butacas es un VARRAY de Butaca, que tendrá hasta 5 butacas, que deberán ser transformados inversamente de A1, A2, A3, A4, A5 a 1, 2, 3, 4, 5...
                verificarButacasDisponibles(movie, sesion, butacasArray)
                    .then(disponibles => {
                        fetch(`/users`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(nuevoUsuario)
                        });
        
                        let idSesion;
                        // Obtener el idSesion desde /sessions/:movieId/:idPelicula/:FechaHora' (únicamente devuelve idSesion) y convertirlo a int
                        fetch(`/sessions/${movie}/${sesion}`)
                            .then(response => response.json())
                            .then(data => {
                                idSesion = parseInt(data.idSesion);
                            })
                            .catch(error => mensajeError('Error al obtener el id de la sesión', error));
        
                            
                        // realizar_reserva(idSesion, Sala, Correo, Nombre, Telefono, Entradas, Butacas)
                        fetch(`/booking`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify(
                                {
                                    idSesion: idSesion,
                                    sala: 1,
                                    correo: correo,
                                    nombre: nombreCompleto,
                                    telefono: telefono,
                                    entradas: {
                                        adultas: entradasAdultos,
                                        menores: entradasMenores,
                                        menus: menusSeleccionados
                                    },
                                    butacas: butacasArray.map(butaca => 
                                        {
                                            let fila = butaca.charCodeAt(0) - 65;
                                            let columna = parseInt(butaca[1]);
                                            return fila * 5 + columna;
                                        }
                                    )
                                }
                            )
                        });
                    })
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
    const fecha = new Date(sesion.split('T')[0]);
    const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
        'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return `${fecha.getDate()} de ${meses[fecha.getMonth()]} de ${fecha.getFullYear()}`;
}

// Formatea la hora de la sesión
function formatearHora(sesion) {
    const hora = new Date(sesion).toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
    return hora.substring(0, 5); // Selecciona solo la hora y los minutos, sin los segundos
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
            document.querySelector('.titulo-seccion').textContent = 'RESERVA DE ENTRADAS: ' + data.Titulo;
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