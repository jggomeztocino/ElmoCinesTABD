-------------------------------------   PELÍCULAS   -------------------------------------
-- Función que devuelve los datos de una película dado su ID
CREATE OR REPLACE FUNCTION listar_pelicula(p_idPelicula IN VARCHAR2) RETURN SYS_REFCURSOR
AS
    c_pelicula SYS_REFCURSOR;
BEGIN
    OPEN c_pelicula FOR
        SELECT * FROM Peliculas WHERE idPelicula = p_idPelicula;
    RETURN c_pelicula;
END;
/

-- Función que devuelve todas las películas
CREATE OR REPLACE FUNCTION listar_peliculas RETURN SYS_REFCURSOR
AS
    c_peliculas SYS_REFCURSOR;
BEGIN
    OPEN c_peliculas FOR
        SELECT Titulo, UrlCover FROM Peliculas;
    RETURN c_peliculas;
END;
/

-- Función que devuelve la película más exitosa (la más reservada) y el número de reservas
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

----------------------------------------   CLIENTES   ---------------------------------------
-- Función que devuelve los datos de un cliente dado su correo
CREATE OR REPLACE FUNCTION listar_cliente (p_correo IN VARCHAR2) RETURN SYS_REFCURSOR
AS
    c_cliente SYS_REFCURSOR;
BEGIN
    OPEN c_cliente FOR
        SELECT * FROM Clientes WHERE Correo = p_correo;
    RETURN c_cliente;
END;

-- Función que devuelve todos los clientes
CREATE OR REPLACE FUNCTION listar_clientes RETURN SYS_REFCURSOR
AS
    c_clientes SYS_REFCURSOR;
BEGIN
    OPEN c_clientes FOR
        SELECT * FROM Clientes;
    RETURN c_clientes;
END;
/

-- Función que devuelve todas las reservas de un cliente dado su correo
CREATE OR REPLACE FUNCTION listar_reservas_cliente(p_correo IN VARCHAR2) RETURN SYS_REFCURSOR
AS
    c_reservas SYS_REFCURSOR;
BEGIN
    OPEN c_reservas FOR
        SELECT * FROM Reservas WHERE Cliente = p_correo;
    RETURN c_reservas;
END;
/

------------------------------------   RESERVAS   ------------------------------------
-- Función que devuelve los datos de una reserva dado su ID
CREATE OR REPLACE FUNCTION listar_reserva(p_idReserva IN NUMBER) RETURN SYS_REFCURSOR
AS
    c_reserva SYS_REFCURSOR;
BEGIN
    OPEN c_reserva FOR
        SELECT * FROM Reservas WHERE idReserva = p_idReserva;
    RETURN c_reserva;
END;

-- Función que devuelve todas las reservas
CREATE OR REPLACE FUNCTION listar_reservas RETURN SYS_REFCURSOR
AS
    c_reservas SYS_REFCURSOR;
BEGIN
    OPEN c_reservas FOR
        SELECT * FROM Reservas;
    RETURN c_reservas;
END;
/

-- Función que devuelve el importe total de una reserva dado su ID
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

-- Función que devuelve el menú más solicitado (de todas las reservas) y el número de solicitudes
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

--------------------------------------------   SESIONES   --------------------------------------------
-- Función que devuelve el número de butacas libres dado el ID de una sesión
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

-- Función que devuelve las sesiones de una película con al menos una butaca libre
CREATE OR REPLACE FUNCTION sesiones_con_butacas_libres(p_idPelicula IN VARCHAR2) RETURN SYS_REFCURSOR
AS
    c_sesiones SYS_REFCURSOR;
BEGIN
    OPEN c_sesiones FOR
        SELECT idSesion, FechaHora FROM Sesiones
        WHERE idPelicula = p_idPelicula AND calcular_butacas_libres(idSesion) > 0;
    RETURN c_sesiones;
END;
/

-- Función para listar una sesión dado su ID
CREATE OR REPLACE FUNCTION listar_sesion(p_idSesion IN NUMBER) RETURN SYS_REFCURSOR
AS
    c_sesion SYS_REFCURSOR;
BEGIN
    OPEN c_sesion FOR
        SELECT * FROM Sesiones WHERE idSesion = p_idSesion;
    RETURN c_sesion;
END;

-- Función que devuelve las butacas ocupadas de una sesión dado su ID
CREATE OR REPLACE FUNCTION butacas_ocupadas(p_idSesion IN NUMBER) RETURN SYS_REFCURSOR
AS
    c_butacas SYS_REFCURSOR;
BEGIN
    OPEN c_butacas FOR
        SELECT idButaca, NumeroSala FROM ButacasReservas
        WHERE idReserva IN (SELECT idReserva FROM Reservas WHERE idSesion = p_idSesion);
    RETURN c_butacas;
END;
/