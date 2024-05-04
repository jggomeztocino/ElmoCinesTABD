-- Creación de paquete para Películas
CREATE OR REPLACE PACKAGE PeliculasPkg AS
    PROCEDURE listar_peliculas;
    PROCEDURE mostrar_info_pelicula(p_idPelicula IN VARCHAR2);
    FUNCTION pelicula_mas_exitosa RETURN VARCHAR2;
END PeliculasPkg;
/

CREATE OR REPLACE PACKAGE BODY PeliculasPkg AS
    PROCEDURE listar_peliculas AS
        CURSOR c_peliculas IS
            SELECT Titulo, UrlCover FROM Peliculas;
    BEGIN
        FOR rec IN c_peliculas LOOP
            DBMS_OUTPUT.PUT_LINE('Título: ' || rec.Titulo || ' - URL Cover: ' || rec.UrlCover);
        END LOOP;
    END listar_peliculas;

    PROCEDURE mostrar_info_pelicula(p_idPelicula IN VARCHAR2) AS
        CURSOR c_pelicula IS
            SELECT * FROM Peliculas WHERE idPelicula = p_idPelicula;
    BEGIN
        FOR rec IN c_pelicula LOOP
            DBMS_OUTPUT.PUT_LINE('ID: ' || rec.idPelicula || ' Título: ' || rec.Titulo ||
                                 ' Directores: ' || rec.Directores || ' Actores: ' || rec.Actores ||
                                 ' Duración: ' || rec.Duracion || ' Sinopsis: ' || rec.Sinopsis ||
                                 ' URL Cover: ' || rec.UrlCover || ' URL Trailer: ' || rec.UrlTrailer);
        END LOOP;
    END mostrar_info_pelicula;

    FUNCTION pelicula_mas_exitosa RETURN VARCHAR2 IS
        pelicula_id VARCHAR2(20);
        max_reservas NUMBER := 0;
        pelicula_titulo VARCHAR2(200);
    BEGIN
        SELECT idPelicula, COUNT(*) INTO pelicula_id, max_reservas
        FROM Reservas r
                 JOIN Sesiones s ON r.idSesion = s.idSesion
        GROUP BY idPelicula
        ORDER BY COUNT(*) DESC
            FETCH FIRST 1 ROWS ONLY;

        SELECT Titulo INTO pelicula_titulo
        FROM Peliculas
        WHERE idPelicula = pelicula_id;

        RETURN pelicula_titulo || ' - Número de reservas: ' || TO_CHAR(max_reservas);
    END pelicula_mas_exitosa;
END PeliculasPkg;
/

-- Creación de paquete para Clientes
CREATE OR REPLACE PACKAGE ClientesPkg AS
    PROCEDURE registrar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2);
    PROCEDURE modificar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2);
    PROCEDURE eliminar_cliente(p_correo IN VARCHAR2);
    PROCEDURE listar_clientes;
    PROCEDURE listar_reservas_cliente(p_correo IN VARCHAR2);
    PROCEDURE InsertOrUpdateCliente(p_correo VARCHAR2, p_nombre VARCHAR2, p_telefono VARCHAR2);
END ClientesPkg;
/

CREATE OR REPLACE PACKAGE BODY ClientesPkg AS
    PROCEDURE registrar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2) AS
    BEGIN
        INSERT INTO Clientes (Correo, Nombre, Telefono) VALUES (p_correo, p_nombre, p_telefono);
        COMMIT;
    END registrar_cliente;

    PROCEDURE modificar_cliente(p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_telefono IN VARCHAR2) AS
    BEGIN
        UPDATE Clientes SET Nombre = p_nombre, Telefono = p_telefono WHERE Correo = p_correo;
        COMMIT;
    END modificar_cliente;

    PROCEDURE eliminar_cliente(p_correo IN VARCHAR2) AS
    BEGIN
        DELETE FROM Clientes WHERE Correo = p_correo;
        COMMIT;
    END eliminar_cliente;

    PROCEDURE listar_clientes AS
        CURSOR c_clientes IS
            SELECT * FROM Clientes;
    BEGIN
        FOR rec IN c_clientes LOOP
            DBMS_OUTPUT.PUT_LINE('Correo: ' || rec.Correo || ' - Nombre: ' || rec.Nombre || ' - Teléfono: ' || rec.Telefono);
        END LOOP;
    END listar_clientes;

    PROCEDURE listar_reservas_cliente(p_correo IN VARCHAR2) AS
        CURSOR c_reservas IS
            SELECT * FROM Reservas WHERE Cliente = p_correo;
    BEGIN
        FOR rec IN c_reservas LOOP
            DBMS_OUTPUT.PUT_LINE('ID Reserva: ' || rec.idReserva || ' - Cliente: ' || rec.Cliente ||
                                 ' - Forma de Pago: ' || rec.FormaPago || ' - Fecha de Compra: ' || rec.FechaCompra);
        END LOOP;
    END listar_reservas_cliente;

    PROCEDURE InsertOrUpdateCliente(p_correo VARCHAR2, p_nombre VARCHAR2, p_telefono VARCHAR2) IS
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
END ClientesPkg;
/

-- Creación de paquete para Reservas y Sesiones
CREATE OR REPLACE PACKAGE ReservasSesionesPkg AS
    FUNCTION calcular_importe_total(id_reserva_in NUMBER) RETURN NUMBER;
    FUNCTION calcular_butacas_libres(id_sesion_in NUMBER) RETURN NUMBER;
    PROCEDURE realizar_reserva(sesion IN NUMBER, sala IN NUMBER, email IN VARCHAR2, nom IN VARCHAR2, tfn IN VARCHAR2, v_entradas IN TipoEntradaArray, v_butacas IN ButacasSeleccionadas);
    PROCEDURE eliminar_reserva(p_idReserva IN NUMBER);
    PROCEDURE listar_reservas;
    PROCEDURE sesiones_con_butacas_libres(p_idPelicula IN VARCHAR2);
    PROCEDURE butacas_ocupadas(p_idSesion IN NUMBER);
END ReservasSesionesPkg;
/

CREATE OR REPLACE PACKAGE BODY ReservasSesionesPkg AS
    FUNCTION calcular_importe_total(id_reserva_in NUMBER) RETURN NUMBER IS
        total NUMBER := 0;
    BEGIN
        SELECT SUM(e.Precio)
        INTO total
        FROM Reservas r,
             TABLE(r.Entradas) e
        WHERE r.idReserva = id_reserva_in;

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

    FUNCTION calcular_butacas_libres(id_sesion_in NUMBER) RETURN NUMBER IS
        total_butacas NUMBER;
        butacas_reservadas NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO total_butacas
        FROM Butacas b
                 JOIN Sesiones s ON b.NumeroSala = s.NumeroSala
        WHERE s.idSesion = id_sesion_in;

        SELECT COUNT(*)
        INTO butacas_reservadas
        FROM ButacasReservas br
                 JOIN Reservas r ON br.idReserva = r.idReserva
        WHERE r.idSesion = id_sesion_in;

        RETURN total_butacas - butacas_reservadas;
    END calcular_butacas_libres;

    PROCEDURE realizar_reserva(sesion IN NUMBER, sala IN NUMBER, email IN VARCHAR2, nom IN VARCHAR2, tfn IN VARCHAR2, v_entradas IN TipoEntradaArray, v_butacas IN ButacasSeleccionadas) AS
        pago VARCHAR2(20) := 'Online';
        fCompra DATE := SYSDATE;
        nuevoIdReserva NUMBER;
    BEGIN
        INSERT INTO Clientes (Correo, Nombre, Telefono) VALUES (email, nom, tfn);

        SELECT secuencia_idReserva.NEXTVAL INTO nuevoIdReserva FROM dual;
        INSERT INTO Reservas (idReserva, idSesion, Cliente, FormaPago, FechaCompra, Entradas)
        VALUES (nuevoIdReserva, sesion, email, pago, fCompra, v_entradas);

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
        DELETE FROM Reservas WHERE idReserva = p_idReserva;
        COMMIT;
    END eliminar_reserva;

    PROCEDURE listar_reservas AS
        CURSOR c_reservas IS
            SELECT * FROM Reservas;
    BEGIN
        FOR rec IN c_reservas LOOP
            DBMS_OUTPUT.PUT_LINE('ID Reserva: ' || rec.idReserva || ' - Cliente: ' || rec.Cliente ||
                                 ' - Forma de Pago: ' || rec.FormaPago || ' - Fecha de Compra: ' || rec.FechaCompra);
        END LOOP;
    END listar_reservas;

    PROCEDURE sesiones_con_butacas_libres(p_idPelicula IN VARCHAR2) AS
        CURSOR c_sesiones IS
            SELECT idSesion, FechaHora FROM Sesiones WHERE idPelicula = p_idPelicula;
    BEGIN
        FOR rec IN c_sesiones LOOP
            IF calcular_butacas_libres(rec.idSesion) > 0 THEN
                DBMS_OUTPUT.PUT_LINE('ID Sesión: ' || rec.idSesion || ' - Fecha y Hora: ' || rec.FechaHora);
            END IF;
        END LOOP;
    END sesiones_con_butacas_libres;

    PROCEDURE butacas_ocupadas(p_idSesion IN NUMBER) AS
        CURSOR c_butacas IS
            SELECT idButaca, NumeroSala FROM ButacasReservas WHERE idReserva IN (SELECT idReserva FROM Reservas WHERE idSesion = p_idSesion);
    BEGIN
        FOR rec IN c_butacas LOOP
            DBMS_OUTPUT.PUT_LINE('ID Butaca: ' || rec.idButaca || ' - Número de Sala: ' || rec.NumeroSala);
        END LOOP;
    END butacas_ocupadas;
END ReservasSesionesPkg;
/
