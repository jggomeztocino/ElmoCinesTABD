-- Creación de procedimiento para listar la cartelera actual
CREATE OR REPLACE PROCEDURE ListarCartelera(p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona título y URL de la imagen de la portada de las películas
    OPEN p_cursor FOR
        SELECT Titulo, UrlCover
        FROM Peliculas;
END;
/

-- Creación de procedimiento para listar información detallada de una película específica
CREATE OR REPLACE PROCEDURE ListarPelicula(p_idPelicula IN Peliculas.idPelicula%TYPE, p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona detalles de la película basados en el ID proporcionado
    OPEN p_cursor FOR
        SELECT Titulo, Directores, Actores, Duracion, Sinopsis, UrlTrailer, UrlCover
        FROM Peliculas
        WHERE idPelicula = p_idPelicula;
END;
/

-- Creación de procedimiento para listar sesiones disponibles de una película
CREATE OR REPLACE PROCEDURE ListarSesionesPelicula(p_idPelicula IN Peliculas.idPelicula%TYPE, p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona fechas y horas de las sesiones de una película
    OPEN p_cursor FOR
        SELECT s.FechaHora
        FROM Sesiones s
        WHERE s.idPelicula = p_idPelicula
        AND (SELECT COUNT(*)
            FROM Butacas b
            LEFT JOIN ButacasReservas br ON b.idButaca = br.refButaca.idButaca
            WHERE br.refSesion.idSesion = s.idSesion
        ) < 30; -- Asegura que haya menos de 30 butacas reservadas para la sesión
END;
/

-- Creación de procedimiento para listar butacas ocupadas en una sesión
CREATE OR REPLACE PROCEDURE ListarButacasOcupadas(p_idSesion IN Sesiones.idSesion%TYPE, p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona las butacas ocupadas para una sesión
    OPEN p_cursor FOR
        SELECT br.refButaca.idButaca
        FROM ButacasReservas br
        JOIN Reservas r ON br.refReserva = r.idReserva
        WHERE r.idSesion = p_idSesion;
END;
/

-- Creación de procedimiento para realizar una reserva
CREATE OR REPLACE PROCEDURE RealizarReserva(
    pCorreo IN Clientes.Correo%TYPE,
    pNombre IN Clientes.Nombre%TYPE,
    pTelefono IN Clientes.Telefono%TYPE,
    pIdSesion IN Sesiones.idSesion%TYPE,
    pFormaPago IN Reservas.FormaPago%TYPE,
    pFechaCompra TIMESTAMP,
    pButacas SYS.ODCIVARCHAR2LIST, -- Lista de pares idButaca-NumeroSala
    pEntradas TipoEntradaArray -- Array de entradas con descripción y precio
) AS
    vCliente REF TipoCliente;
    vReserva REF TipoReserva;
    vSesion REF TipoSesion;
    vButaca REF TipoButaca;
    vIdReserva Reservas.idReserva%TYPE;
BEGIN
    -- Comprobar si existe el cliente
    BEGIN
        SELECT REF(c) INTO vCliente FROM Clientes c WHERE c.Correo = pCorreo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no existe, crear cliente
            INSERT INTO Clientes (Correo, Nombre, Telefono)
            VALUES (pCorreo, pNombre, pTelefono)
            RETURNING REF(c) INTO vCliente;
    END;

    -- Actualizar el cliente (si no existía, se creó en el paso anterior y aquí simplemente se vuelve a introducir su misma información)
    UPDATE Clientes c
    SET Nombre = pNombre, Telefono = pTelefono
    WHERE c.Correo = pCorreo;

    -- Obtener la referencia de la sesión
    SELECT REF(s) INTO vSesion FROM Sesiones s WHERE s.idSesion = pIdSesion;
    
    -- Crear reserva
    INSERT INTO Reservas (idReserva, idSesion, idCliente, FormaPago, FechaCompra, Entradas)
    VALUES (secuencia_idReserva.NEXTVAL, vSesion, vCliente, pFormaPago, pFechaCompra, pEntradas)
    RETURNING idReserva INTO vIdReserva;

    -- Crear asociaciones de butacas a la reserva
    FOR i IN 1..pButacas.COUNT LOOP
        SELECT REF(b) INTO vButaca FROM Butacas b 
        WHERE b.idButaca = SUBSTR(pButacas(i), 1, INSTR(pButacas(i), '-') - 1)
        AND b.NumeroSala = SUBSTR(pButacas(i), INSTR(pButacas(i), '-') + 1);

        INSERT INTO ButacasReservas (idButacaReserva, refButaca, refReserva)
        VALUES (secuencia_idButacaReserva.NEXTVAL, vButaca, (SELECT REF(r) FROM Reservas r WHERE r.idReserva = vIdReserva));
    END LOOP;
    
    COMMIT;
END;
/

-- Creación de procedimiento para eliminar una reserva
CREATE OR REPLACE PROCEDURE EliminarReserva(
    p_id_reserva IN Reservas.idReserva%TYPE
) AS
BEGIN
    -- Eliminar las entradas asociadas a la reserva
    DELETE FROM TABLE (
        SELECT Entradas
        FROM Reservas
        WHERE idReserva = p_id_reserva
    );

    -- Eliminar las asociaciones entre butacas y la reserva
    DELETE FROM ButacasReservas
    WHERE refReserva IN (SELECT REF(r) FROM Reservas r WHERE r.idReserva = p_id_reserva);

    -- Eliminar la reserva
    DELETE FROM Reservas
    WHERE idReserva = p_id_reserva;

    COMMIT;
END;
/

-- Creación de procedimiento para listar todas las reservas
CREATE OR REPLACE PROCEDURE ListarReservas(p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona detalles básicos de las reservas
    OPEN p_cursor FOR
        SELECT r.idReserva, r.idSesion, r.idCliente, r.FechaCompra
        FROM Reservas r;
END;
/

-- Creación de procedimiento para listar detalles de una reserva específica
CREATE OR REPLACE PROCEDURE ListarReserva(p_idReserva IN Reservas.idReserva%TYPE, p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona detalles de una reserva específica
    OPEN p_cursor FOR
        SELECT r.idReserva, r.idSesion, r.idCliente, r.FechaCompra
        FROM Reservas r
        WHERE r.idReserva = p_idReserva;
END;
/

-- Creación de procedimiento para registrar un nuevo cliente
CREATE OR REPLACE PROCEDURE RegistrarCliente(
    p_nombre_cliente IN Clientes.Nombre%TYPE,
    p_correo_cliente IN Clientes.Correo%TYPE,
    p_telefono_cliente IN Clientes.Telefono%TYPE
) AS
BEGIN
    -- Insertar un nuevo cliente en la tabla Clientes
    INSERT INTO Clientes (Correo, Nombre, Telefono)
    VALUES (p_correo_cliente, p_nombre_cliente, p_telefono_cliente);
    
    COMMIT;
END;
/

-- Creación de procedimiento para modificar detalles de un cliente
CREATE OR REPLACE PROCEDURE ModificarCliente(
    p_id_cliente IN Clientes.Correo%TYPE,
    p_nombre_cliente IN Clientes.Nombre%TYPE,
    p_telefono_cliente IN Clientes.Telefono%TYPE
) AS
BEGIN
    -- Actualizar información de un cliente existente
    UPDATE Clientes
    SET Nombre = p_nombre_cliente, Telefono = p_telefono_cliente
    WHERE Correo = p_id_cliente;
    
    COMMIT;
END;
/

-- Creación de procedimiento para eliminar un cliente
CREATE OR REPLACE PROCEDURE EliminarCliente(
    p_id_cliente IN Clientes.Correo%TYPE
) AS
BEGIN
    -- Eliminar un cliente de la tabla Clientes
    DELETE FROM Clientes
    WHERE Correo = p_id_cliente;
    
    COMMIT;
END;
/

-- Creación de procedimiento para listar todos los clientes
CREATE OR REPLACE PROCEDURE ListarClientes(p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona detalles de todos los clientes
    OPEN p_cursor FOR
        SELECT Correo, Nombre, Telefono
        FROM Clientes;
END;
/

-- Creación de procedimiento para listar detalles de un cliente específico
CREATE OR REPLACE PROCEDURE ListarCliente(p_idCliente IN Clientes.Correo%TYPE, p_cursor OUT SYS_REFCURSOR)
IS
BEGIN
    -- Abre un cursor que selecciona detalles de un cliente específico
    OPEN p_cursor FOR
        SELECT Correo, Nombre, Telefono
        FROM Clientes
        WHERE Correo = p_idCliente;
END;
/
