document.addEventListener("DOMContentLoaded", function() {
    const apiUrl = '/users';
    const mainContainer = document.querySelector('.mainContainer');

    // Función para inicializar la interfaz de usuario
    function initUI() {
        mainContainer.innerHTML = `
            <div class="row mb-4">
                <div class="col-12">
                    <label for="searchEmail">Buscar usuario por correo:</label>
                    <input type="email" id="searchEmail" placeholder="Buscar usuario por correo" class="form-control">
                    <button class="btn mt-2" id="searchUserButton">Buscar</button>
                </div>
            </div>
            <div id="usersContainer" class="row"></div>
            <div class="row mt-4">
                <div class="col-12 d-flex justify-content-between">
                    <button class="btn" id="deleteAllUsersButton">Eliminar todos los usuarios</button>
                    <button class="btn btn-info" id="showAllUsersButton">Mostrar todos los usuarios</button>
                </div>
            </div>
        `;
        document.getElementById("searchUserButton").addEventListener("click", searchUser);
        document.getElementById("deleteAllUsersButton").addEventListener("click", deleteAllUsers);
        document.getElementById("showAllUsersButton").addEventListener("click", getAllUsers);
    }

    // Función para obtener todos los usuarios
    async function getAllUsers() {
        try {
            const response = await fetch(apiUrl);
            if (!response.ok) throw new Error('Error al obtener los usuarios');
            const users = await response.json();
            displayUsers(users);
        } catch (error) {
            console.error('getAllUsers:', error.message);
        }
    }

    // Función para buscar un usuario por correo
    async function searchUser() {
        const email = document.getElementById('searchEmail').value;
        if (!validarCorreo(email)) {
            alert('Por favor, introduce un correo válido.');
            return;
        }
        try {
            const response = await fetch(`${apiUrl}/${email}`);
            if (!response.ok) throw new Error('Usuario no encontrado');
            const user = await response.json();
            displayUsers([user]);
        } catch (error) {
            console.error('searchUser:', error.message);
        }
    }

    // Función para validar un correo
    function validarCorreo(email) {
        return /^[^@\s]+@[^@\s]+\.(com|es)(\/\S*)?$/.test(email);
    }

    // Función para mostrar los usuarios en el HTML
    function displayUsers(users) {
        const usersContainer = document.getElementById('usersContainer');
        usersContainer.innerHTML = '';
        users.forEach(user => {
            const userHtml = `
                <div class="col-12 col-lg-3 mb-3">
                    <div class="card text-white">
                        <div class="card-body">
                            <h5 class="card-title">${user.name}</h5>
                            <p class="card-text">${user._id}</p>
                            <p class="card-text">${user.phone}</p>
                            <button class="btn btn-danger mb-3" data-email="${user._id}">Eliminar</button>
                            <button class="btn btn-primary" data-edit-email="${user._id}">Editar</button>
                        </div>
                    </div>
                </div>
            `;
            usersContainer.innerHTML += userHtml;
        });
        document.querySelectorAll('[data-email]').forEach(button => {
            button.addEventListener('click', function() {
                deleteUser(this.getAttribute('data-email'));
            });
        });
        document.querySelectorAll('[data-edit-email]').forEach(button => {
            button.addEventListener('click', function() {
                const email = this.getAttribute('data-edit-email');
                editUserModal(email);
            });
        });
    }

    // Función para eliminar un usuario
    async function deleteUser(email) {
        try {
            const response = await fetch(`${apiUrl}/${email}`, { method: 'DELETE' });
            if (!response.ok) throw new Error('Error al eliminar el usuario');
            alert('Usuario eliminado correctamente');
            await getAllUsers();
        } catch (error) {
            console.error('deleteUser:', error.message);
        }
    }

    // Función para eliminar todos los usuarios
    async function deleteAllUsers() {
        try {
            const response = await fetch(apiUrl, { method: 'DELETE' });
            if (!response.ok) throw new Error('Error al eliminar todos los usuarios');
            alert('Todos los usuarios han sido eliminados');
            await getAllUsers();
        } catch (error) {
            console.error('deleteAllUsers:', error.message);
        }
    }

    // Función para mostrar un modal con un input para editar el nombre de un usuario
    function editUserModal(email) {
        const user = prompt("Ingrese el nuevo nombre del usuario:");
        if (user !== null && user.trim() !== "") {
            updateUser(email, { name: user });
        } else {
            alert("El nombre no puede estar vacío.");
        }
        // Implementar telefono
    }

    // Función para actualizar un usuario
    async function updateUser(email, data) {
        try {
            const response = await fetch(`${apiUrl}/${email}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(data),
            });
            if (!response.ok) throw new Error('Error al actualizar el usuario');
            alert('Usuario actualizado correctamente');
            await getAllUsers();
        } catch (error) {
            console.error('updateUser:', error.message);
        }
    }

    initUI();
    getAllUsers();
});
