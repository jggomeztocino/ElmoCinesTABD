-- Definición de las cabeceras de los paquetes
CREATE OR REPLACE PACKAGE ClientesPkg AS
    PROCEDURE InsertOrUpdateCliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2);
    PROCEDURE modificar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2);
    PROCEDURE eliminar_cliente(p_correo IN VARCHAR2);
    PROCEDURE eliminar_todos_clientes;
    FUNCTION listar_cliente(p_correo IN VARCHAR2) RETURN SYS_REFCURSOR;
    FUNCTION listar_clientes RETURN SYS_REFCURSOR;
    FUNCTION listar_reservas_cliente(p_correo IN VARCHAR2) RETURN SYS_REFCURSOR;
END ClientesPkg;
/

CREATE OR REPLACE PACKAGE PeliculasPkg AS
    PROCEDURE eliminar_pelicula(p_idPelicula IN VARCHAR2);
    PROCEDURE eliminar_todas_peliculas;
    FUNCTION listar_pelicula(p_idPelicula IN VARCHAR2) RETURN SYS_REFCURSOR;
    FUNCTION listar_peliculas RETURN SYS_REFCURSOR;
    FUNCTION pelicula_mas_exitosa RETURN VARCHAR2;
END PeliculasPkg;
/

CREATE OR REPLACE PACKAGE ReservasPkg AS
    PROCEDURE realizar_reserva (
        sesion IN NUMBER,
        sala IN NUMBER,
        email IN VARCHAR2,
        nom IN VARCHAR2,
        tfn IN VARCHAR2,
        v_entradas IN TipoEntradaArray,
        v_butacas IN ButacasSeleccionadas
    );
    PROCEDURE eliminar_reserva(p_idReserva IN NUMBER);
    FUNCTION listar_reserva(p_idReserva IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION listar_reservas RETURN SYS_REFCURSOR;
    FUNCTION calcular_importe_total(id_reserva_in NUMBER) RETURN NUMBER;
    FUNCTION menu_mas_solicitado RETURN VARCHAR2;
END ReservasPkg;
/

CREATE OR REPLACE PACKAGE SesionesPkg AS
    PROCEDURE eliminar_sesion(p_idSesion IN NUMBER);
    PROCEDURE eliminar_sesiones_pelicula(p_idPelicula IN VARCHAR2);
    PROCEDURE eliminar_todas_sesiones;
    FUNCTION calcular_butacas_libres(p_idSesion IN NUMBER) RETURN NUMBER;
    FUNCTION sesiones_con_butacas_libres(p_idPelicula IN VARCHAR2) RETURN SYS_REFCURSOR;
    FUNCTION listar_sesion(p_idSesion IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION butacas_ocupadas(p_idSesion IN NUMBER) RETURN SYS_REFCURSOR;
END SesionesPkg;
/

-- Definición de los cuerpos de los paquetes
CREATE OR REPLACE PACKAGE BODY ClientesPkg AS
    PROCEDURE InsertOrUpdateCliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2)
    AS
        fila_actualizada INTEGER;
    BEGIN
        UPDATE Clientes
        SET Nombre = p_nombre, Telefono = p_telefono
        WHERE Correo = p_correo;

        fila_actualizada := SQL%ROWCOUNT;

        IF fila_actualizada = 0 THEN
            INSERT INTO Clientes (Correo, Nombre, Telefono)
            VALUES (p_correo, p_nombre, p_telefono);
        END IF;
    END InsertOrUpdateCliente;

    FUNCTION listar_cliente (p_correo IN VARCHAR2) RETURN SYS_REFCURSOR
    AS
        c_cliente SYS_REFCURSOR;
    BEGIN
        OPEN c_cliente FOR
            SELECT * FROM Clientes WHERE Correo = p_correo;
        RETURN c_cliente;
    END listar_cliente;

    FUNCTION listar_clientes RETURN SYS_REFCURSOR
    AS
        c_clientes SYS_REFCURSOR;
    BEGIN
        OPEN c_clientes FOR
            SELECT * FROM Clientes;
        RETURN c_clientes;
    END listar_clientes;

    FUNCTION listar_reservas_cliente(p_correo IN VARCHAR2) RETURN SYS_REFCURSOR
    AS
        c_reservas SYS_REFCURSOR;
    BEGIN
        OPEN c_reservas FOR
            SELECT * FROM Reservas WHERE Cliente = p_correo;
        RETURN c_reservas;
    END listar_reservas_cliente;

    PROCEDURE modificar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2) AS
    BEGIN
        -- Antes de modificar el cliente, se comprueba si existe (disparador)
        UPDATE Clientes SET Nombre = p_nombre, Telefono = p_telefono WHERE Correo = p_correo;
        COMMIT;
    END modificar_cliente;

    PROCEDURE eliminar_cliente(p_correo IN VARCHAR2) AS
    BEGIN
        -- Antes de eliminar el cliente, se eliminan las reservas asociadas (Disparador)
        DELETE FROM Clientes WHERE Correo = p_correo;
        COMMIT;
    END eliminar_cliente;

    PROCEDURE eliminar_todos_clientes AS
    BEGIN
        -- Antes de eliminar todos los clientes, se eliminan las reservas asociadas (Disparador)
        DELETE FROM Clientes;
        COMMIT;
    END eliminar_todos_clientes;
END ClientesPkg;
/

CREATE OR REPLACE PACKAGE BODY PeliculasPkg AS
    FUNCTION listar_pelicula(p_idPelicula IN VARCHAR2) RETURN SYS_REFCURSOR
    AS
        c_pelicula SYS_REFCURSOR;
    BEGIN
        OPEN c_pelicula FOR
            SELECT * FROM Peliculas WHERE idPelicula = p_idPelicula;
        RETURN c_pelicula;
    END listar_pelicula;

    FUNCTION listar_peliculas RETURN SYS_REFCURSOR
    AS
        c_peliculas SYS_REFCURSOR;
    BEGIN
        OPEN c_peliculas FOR
            SELECT Titulo, UrlCover FROM Peliculas;
        RETURN c_peliculas;
    END listar_peliculas;

    FUNCTION pelicula_mas_exitosa
    RETURN VARCHAR2 IS
        pelicula_id VARCHAR2(20);
        max_reservas NUMBER := 0;
        pelicula_titulo VARCHAR2(200);
    BEGIN
        -- Contar reservas por película y seleccionar la más reservada
        SELECT idPelicula, COUNT(*) INTO pelicula_id, max_reservas
        FROM Reservas r
                JOIN Sesiones s ON r.idSesion = s.idSesion
        GROUP BY idPelicula
        ORDER BY COUNT(*) DESC
            FETCH FIRST 1 ROWS ONLY;

        -- Obtener el título de la película más exitosa
        SELECT Titulo INTO pelicula_titulo
        FROM Peliculas
        WHERE idPelicula = pelicula_id;

        RETURN pelicula_titulo || ' - Número de reservas: ' || TO_CHAR(max_reservas);
    END pelicula_mas_exitosa;

    PROCEDURE eliminar_pelicula(p_idPelicula IN VARCHAR2) AS
    BEGIN
        -- Antes de eliminar la película, se eliminan las sesiones, reservas y butacas asociadas (Disparador)
        DELETE FROM Peliculas WHERE idPelicula = p_idPelicula;
        COMMIT;
    END eliminar_pelicula;

    PROCEDURE eliminar_todas_peliculas AS
    BEGIN
        -- Antes de eliminar todas las películas, se eliminan las sesiones, reservas y butacas asociadas (Disparador)
        DELETE FROM Peliculas;
        COMMIT;
    END eliminar_todas_peliculas;
END PeliculasPkg;
/

CREATE OR REPLACE PACKAGE BODY ReservasPkg AS
    FUNCTION listar_reserva(p_idReserva IN NUMBER) RETURN SYS_REFCURSOR
    AS
        c_reserva SYS_REFCURSOR;
    BEGIN
        OPEN c_reserva FOR
            SELECT * FROM Reservas WHERE idReserva = p_idReserva;
        RETURN c_reserva;
    END listar_reserva;

    FUNCTION listar_reservas RETURN SYS_REFCURSOR
    AS
        c_reservas SYS_REFCURSOR;
    BEGIN
        OPEN c_reservas FOR
            SELECT * FROM Reservas;
        RETURN c_reservas;
    END listar_reservas;

    FUNCTION calcular_importe_total(id_reserva_in NUMBER)
        RETURN NUMBER IS
        total NUMBER := 0;
    BEGIN
        -- Sumar precios de las entradas
        SELECT SUM(e.Precio)
        INTO total
        FROM Reservas r,
            TABLE(r.Entradas) e
        WHERE r.idReserva = id_reserva_in;

        -- Sumar precios de los menús de las entradas
        FOR rec IN (SELECT e.idMenu
                    FROM Reservas r,
                        TABLE(r.Entradas) e
                    WHERE r.idReserva = id_reserva_in)
            LOOP
                SELECT m.Precio INTO total
                FROM Menus m
                WHERE m.idMenu = rec.idMenu;
            END LOOP;

        RETURN total;
    END calcular_importe_total;

    FUNCTION menu_mas_solicitado
        RETURN VARCHAR2 IS
        menu_id NUMBER;
        max_count NUMBER := 0;
        menu_description VARCHAR2(200);
    BEGIN
        SELECT idMenu, COUNT(idMenu) INTO menu_id, max_count
        FROM Reservas r, TABLE(r.Entradas) e
        GROUP BY idMenu
        ORDER BY COUNT(idMenu) DESC
            FETCH FIRST 1 ROWS ONLY;

        -- Obtener la descripción del menú más solicitado
        SELECT Descripcion INTO menu_description
        FROM Menus
        WHERE idMenu = menu_id;

        RETURN menu_description || ' - Solicitudes: ' || TO_CHAR(max_count);
    END menu_mas_solicitado;

    PROCEDURE realizar_reserva (
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
    END realizar_reserva;

    PROCEDURE eliminar_reserva(p_idReserva IN NUMBER) AS
    BEGIN
        -- Antes de eliminar la reserva, se eliminan las butacas asociadas (Disparador)
        DELETE FROM Reservas WHERE idReserva = p_idReserva;
        COMMIT;
    END eliminar_reserva;
END ReservasPkg;
/

CREATE OR REPLACE PACKAGE BODY SesionesPkg AS
    FUNCTION calcular_butacas_libres(p_idSesion IN NUMBER) RETURN NUMBER
    AS
        total_butacas NUMBER;
        butacas_reservadas NUMBER;
    BEGIN
        -- Contar total de butacas en la sala de la sesión
        SELECT COUNT(*)
        INTO total_butacas
        FROM Butacas b
                JOIN Sesiones s ON b.NumeroSala = s.NumeroSala
        WHERE s.idSesion = p_idSesion;

        -- Contar butacas ya reservadas para esa sesión
        SELECT COUNT(*)
        INTO butacas_reservadas
        FROM ButacasReservas br
                JOIN Reservas r ON br.idReserva = r.idReserva
        WHERE r.idSesion = p_idSesion;

        RETURN total_butacas - butacas_reservadas;
    END calcular_butacas_libres;

    FUNCTION sesiones_con_butacas_libres(p_idPelicula IN VARCHAR2) RETURN SYS_REFCURSOR
    AS
        c_sesiones SYS_REFCURSOR;
    BEGIN
        OPEN c_sesiones FOR
            SELECT idSesion, FechaHora FROM Sesiones
            WHERE idPelicula = p_idPelicula AND SesionesPkg.calcular_butacas_libres(idSesion) > 0;
        RETURN c_sesiones;
    END sesiones_con_butacas_libres;

    FUNCTION listar_sesion(p_idSesion IN NUMBER) RETURN SYS_REFCURSOR
    AS
        c_sesion SYS_REFCURSOR;
    BEGIN
        OPEN c_sesion FOR
            SELECT * FROM Sesiones WHERE idSesion = p_idSesion;
        RETURN c_sesion;
    END listar_sesion;

    FUNCTION butacas_ocupadas(p_idSesion IN NUMBER) RETURN SYS_REFCURSOR
    AS
        c_butacas SYS_REFCURSOR;
    BEGIN
        OPEN c_butacas FOR
            SELECT idButaca, NumeroSala FROM ButacasReservas
            WHERE idReserva IN (SELECT idReserva FROM Reservas WHERE idSesion = p_idSesion);
        RETURN c_butacas;
    END butacas_ocupadas;

    PROCEDURE eliminar_sesion(p_idSesion IN NUMBER) AS
    BEGIN
        -- Antes de eliminar la sesión, se eliminan las reservas y butacas asociadas (Disparador)
        DELETE FROM Sesiones WHERE idSesion = p_idSesion;
        COMMIT;
    END eliminar_sesion;

    PROCEDURE eliminar_sesiones_pelicula(p_idPelicula IN VARCHAR2) AS
    BEGIN
        -- Antes de eliminar todas las sesiones, se eliminan las reservas y butacas asociadas (Disparador)
        DELETE FROM Sesiones WHERE idPelicula = p_idPelicula;
        COMMIT;
    END eliminar_sesiones_pelicula;

    PROCEDURE eliminar_todas_sesiones AS
    BEGIN
        -- Antes de eliminar todas las sesiones, se eliminan las reservas y butacas asociadas (Disparador)
        DELETE FROM Sesiones;
        COMMIT;
    END eliminar_todas_sesiones;
END SesionesPkg;
/

COMMIT;