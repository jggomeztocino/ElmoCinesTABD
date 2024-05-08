-- Función para calcular el importe total de una reserva
CREATE OR REPLACE FUNCTION calcular_importe_total(id_reserva_in NUMBER)
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
END;
/

-- Función para calcular el número de butacas libres para una sesión
CREATE OR REPLACE FUNCTION calcular_butacas_libres(id_sesion_in NUMBER)
    RETURN NUMBER IS
    total_butacas NUMBER;
    butacas_reservadas NUMBER;
BEGIN
    -- Contar total de butacas en la sala de la sesión
    SELECT COUNT(*)
    INTO total_butacas
    FROM Butacas b
             JOIN Sesiones s ON b.NumeroSala = s.NumeroSala
    WHERE s.idSesion = id_sesion_in;

    -- Contar butacas ya reservadas para esa sesión
    SELECT COUNT(*)
    INTO butacas_reservadas
    FROM ButacasReservas br
             JOIN Reservas r ON br.idReserva = r.idReserva
    WHERE r.idSesion = id_sesion_in;

    RETURN total_butacas - butacas_reservadas;
END;
/

-- Función para obtener el menú más solicitado por los clientes
CREATE OR REPLACE FUNCTION menu_mas_solicitado
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
END;
/

-- Función para obtener la película más exitosa
CREATE OR REPLACE FUNCTION pelicula_mas_exitosa
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
END;
/