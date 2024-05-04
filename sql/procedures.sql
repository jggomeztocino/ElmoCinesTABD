-- Procedimiento para listar el Título y el UrlCover de todas las películas
CREATE OR REPLACE PROCEDURE listar_peliculas AS
    CURSOR c_peliculas IS
        SELECT Titulo, UrlCover FROM Peliculas;
BEGIN
    FOR rec IN c_peliculas LOOP
            DBMS_OUTPUT.PUT_LINE('Título: ' || rec.Titulo || ' - URL Cover: ' || rec.UrlCover);
        END LOOP;
END;
/

-- Procedimiento para listar toda la información de una película, dado su ID
CREATE OR REPLACE PROCEDURE mostrar_info_pelicula(p_idPelicula IN VARCHAR2) AS
    CURSOR c_pelicula IS
        SELECT * FROM Peliculas WHERE idPelicula = p_idPelicula;
BEGIN
    FOR rec IN c_pelicula LOOP
            DBMS_OUTPUT.PUT_LINE('ID: ' || rec.idPelicula || ' Título: ' || rec.Titulo ||
                                 ' Directores: ' || rec.Directores || ' Actores: ' || rec.Actores ||
                                 ' Duración: ' || rec.Duracion || ' Sinopsis: ' || rec.Sinopsis ||
                                 ' URL Cover: ' || rec.UrlCover || ' URL Trailer: ' || rec.UrlTrailer);
        END LOOP;
END;
/

-- Procedimiento para listar el idSesion y la FechaHora de las Sesiones programadas para una Película que tenga al menos una butaca libre
CREATE OR REPLACE PROCEDURE sesiones_con_butacas_libres(p_idPelicula IN VARCHAR2) AS
    CURSOR c_sesiones IS
        SELECT idSesion, FechaHora FROM Sesiones WHERE idPelicula = p_idPelicula;
BEGIN
    FOR rec IN c_sesiones LOOP
            IF calcular_butacas_libres(rec.idSesion) > 0 THEN
                DBMS_OUTPUT.PUT_LINE('ID Sesión: ' || rec.idSesion || ' - Fecha y Hora: ' || rec.FechaHora);
            END IF;
        END LOOP;
END;
/

-- Procedimiento para listar las butacas ocupadas para un idSesion dado
CREATE OR REPLACE PROCEDURE butacas_ocupadas(p_idSesion IN NUMBER) AS
    CURSOR c_butacas IS
        SELECT idButaca, NumeroSala FROM ButacasReservas WHERE idReserva IN (SELECT idReserva FROM Reservas WHERE idSesion = p_idSesion);
BEGIN
    FOR rec IN c_butacas LOOP
            DBMS_OUTPUT.PUT_LINE('ID Butaca: ' || rec.idButaca || ' - Número de Sala: ' || rec.NumeroSala);
        END LOOP;
END;
/

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

-- Procedimiento para listar todas las reservas
CREATE OR REPLACE PROCEDURE listar_reservas AS
    CURSOR c_reservas IS
        SELECT * FROM Reservas;
BEGIN
    FOR rec IN c_reservas LOOP
            DBMS_OUTPUT.PUT_LINE('ID Reserva: ' || rec.idReserva || ' - Cliente: ' || rec.Cliente ||
                                 ' - Forma de Pago: ' || rec.FormaPago || ' - Fecha de Compra: ' || rec.FechaCompra);
        END LOOP;
END;
/

-- Procedimiento para listar todas las reservas de un cliente
CREATE OR REPLACE PROCEDURE listar_reservas_cliente(p_correo IN VARCHAR2) AS
    CURSOR c_reservas IS
        SELECT * FROM Reservas WHERE Cliente = p_correo;
BEGIN
    FOR rec IN c_reservas LOOP
            DBMS_OUTPUT.PUT_LINE('ID Reserva: ' || rec.idReserva || ' - Cliente: ' || rec.Cliente ||
                                 ' - Forma de Pago: ' || rec.FormaPago || ' - Fecha de Compra: ' || rec.FechaCompra);
        END LOOP;
END;
/

-- Procedimiento para registrar un cliente, dado su correo, nombre y teléfono
CREATE OR REPLACE PROCEDURE registrar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2) AS
BEGIN
    -- Antes de registrar el cliente, se comprueba si ya existe (disparador)
    INSERT INTO Clientes (Correo, Nombre, Telefono) VALUES (p_correo, p_nombre, p_telefono);
    COMMIT;
END;
/

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

-- Procedimiento para listar todos los clientes
CREATE OR REPLACE PROCEDURE listar_clientes AS
    CURSOR c_clientes IS
        SELECT * FROM Clientes;
BEGIN
    FOR rec IN c_clientes LOOP
            DBMS_OUTPUT.PUT_LINE('Correo: ' || rec.Correo || ' - Nombre: ' || rec.Nombre || ' - Teléfono: ' || rec.Telefono);
        END LOOP;
END;
/