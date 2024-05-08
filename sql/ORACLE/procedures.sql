-------------------------------------   PELÍCULAS   -------------------------------------
-- Procedimiento para eliminar una película, dado su ID
CREATE OR REPLACE PROCEDURE eliminar_pelicula(p_idPelicula IN VARCHAR2) AS
BEGIN
    -- Antes de eliminar la película, se eliminan las sesiones, reservas y butacas asociadas (Disparador)
    DELETE FROM Peliculas WHERE idPelicula = p_idPelicula;
    COMMIT;
END;

-- Procedimiento para elmininar todas las películas
CREATE OR REPLACE PROCEDURE eliminar_todas_peliculas AS
BEGIN
    -- Antes de eliminar todas las películas, se eliminan las sesiones, reservas y butacas asociadas (Disparador)
    DELETE FROM Peliculas;
    COMMIT;
END;

----------------------------------------   CLIENTES   ---------------------------------------
-- Procedimiento para modificar un cliente, dado su correo, nombre y teléfono
CREATE OR REPLACE PROCEDURE modificar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2) AS
BEGIN
    -- Antes de modificar el cliente, se comprueba si existe (disparador)
    UPDATE Clientes SET Nombre = p_nombre, Telefono = p_telefono WHERE Correo = p_correo;
    COMMIT;
END;
/

-- Procedimiento para eliminar un cliente, dado su correo
CREATE OR REPLACE PROCEDURE eliminar_cliente(p_correo IN VARCHAR2) AS
BEGIN
    -- Antes de eliminar el cliente, se eliminan las reservas asociadas (Disparador)
    DELETE FROM Clientes WHERE Correo = p_correo;
    COMMIT;
END;
/

-- Procedimiento para eliminar todos los clientes
CREATE OR REPLACE PROCEDURE eliminar_todos_clientes AS
BEGIN
    -- Antes de eliminar todos los clientes, se eliminan las reservas asociadas (Disparador)
    DELETE FROM Clientes;
    COMMIT;
END;

------------------------------------   RESERVAS   ------------------------------------
CREATE OR REPLACE PROCEDURE realizar_reserva (
    sesion IN NUMBER,
    sala IN NUMBER,
    email IN VARCHAR2,
    nom IN VARCHAR2,
    tfn IN VARCHAR2,
    v_entradas IN TipoEntradaArray,
    v_butacas IN ButacasSeleccionadas
) AS
    pago VARCHAR2(20) := 'Online';
    fCompra DATE := SYSDATE;
    nuevoIdReserva NUMBER;
    clienteExistente NUMBER;
BEGIN
    INSERT INTO Clientes (Correo, Nombre, Telefono) VALUES (email, nom, tfn);

    -- Generar el nuevo ID de reserva y realizar la inserción
    SELECT secuencia_idReserva.NEXTVAL INTO nuevoIdReserva FROM dual;
    INSERT INTO Reservas (idReserva, idSesion, Cliente, FormaPago, FechaCompra, Entradas)
    VALUES (nuevoIdReserva, sesion, email, pago, fCompra, v_entradas);

    -- Bucle para insertar las butacas seleccionadas
    FOR i IN 1..v_butacas.COUNT LOOP
            INSERT INTO ButacasReservas (idButacaReserva, idButaca, NumeroSala, idReserva)
            VALUES (secuencia_idButacaReserva.NEXTVAL, v_butacas(i), sala, nuevoIdReserva);
        END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- Procedimiento para eliminar una reserva, dado su ID
CREATE OR REPLACE PROCEDURE eliminar_reserva(p_idReserva IN NUMBER) AS
BEGIN
    -- Antes de eliminar la reserva, se eliminan las butacas asociadas (Disparador)
    DELETE FROM Reservas WHERE idReserva = p_idReserva;
    COMMIT;
END;
/

--------------------------------------------   SESIONES   --------------------------------------------
-- Procedimiento para eliminar una sesión, dado su ID
CREATE OR REPLACE PROCEDURE eliminar_sesion(p_idSesion IN NUMBER) AS
BEGIN
    -- Antes de eliminar la sesión, se eliminan las reservas y butacas asociadas (Disparador)
    DELETE FROM Sesiones WHERE idSesion = p_idSesion;
    COMMIT;
END;

-- Procedimiento para eliminar todas las sesiones dado el ID de la película
CREATE OR REPLACE PROCEDURE eliminar_sesiones_pelicula(p_idPelicula IN VARCHAR2) AS
BEGIN
    -- Antes de eliminar todas las sesiones, se eliminan las reservas y butacas asociadas (Disparador)
    DELETE FROM Sesiones WHERE idPelicula = p_idPelicula;
    COMMIT;
END;

-- Procedimiento para eliminar todas las sesiones
CREATE OR REPLACE PROCEDURE eliminar_todas_sesiones AS
BEGIN
    -- Antes de eliminar todas las sesiones, se eliminan las reservas y butacas asociadas (Disparador)
    DELETE FROM Sesiones;
    COMMIT;
END;