CREATE OR REPLACE PROCEDURE ListarCartelera(p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT Titulo, UrlCover
        FROM Peliculas;
END;
/

CREATE OR REPLACE PROCEDURE ListarPelicula(p_idPelicula IN Peliculas.idPelicula%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT Titulo, Directores, Actores, Duracion, Sinopsis, UrlTrailer
        FROM Peliculas
        WHERE idPelicula = p_idPelicula;
END;
/

CREATE OR REPLACE PROCEDURE ListarSesionesPelicula(p_idPelicula IN Peliculas.idPelicula%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT FechaHora
        FROM Sesiones
        WHERE idPelicula = p_idPelicula;
        AND (SELECT COUNT(*)
            FROM Butacas b
            LEFT JOIN ButacasReservas br ON b.idButaca = br.refButaca.idButaca
            WHERE br.refSesion.idSesion = s.idSesion
        ) < 30;
END;
/

CREATE OR REPLACE PROCEDURE ListarButacasOcupadas(p_idSesion IN Sesiones.idSesion%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT BR.refButaca.idButaca
        FROM ButacasReservas BR
        JOIN Reservas R ON BR.refReserva.idReserva = R.idReserva
        JOIN Sesiones S ON R.idSesion.idSesion = S.idSesion
        WHERE S.idSesion = p_idSesion;
END;
/

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
    SELECT REF(c) INTO vCliente FROM Clientes c WHERE c.Correo = pCorreo;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no existe, crear cliente
            INSERT INTO Clientes VALUES (
                pCorreo, pNombre, pTelefono
            )
            RETURNING REF(c) INTO vCliente;
        WHEN OTHERS THEN
            -- Si existe, actualizar cliente
            UPDATE Clientes c SET c.Nombre = pNombre, c.Telefono = pTelefono WHERE c.Correo = pCorreo;
            SELECT REF(c) INTO vCliente FROM Clientes c WHERE c.Correo = pCorreo;
    
    -- Obtener la referencia de la sesión
    SELECT REF(s) INTO vSesion FROM Sesiones s WHERE s.idSesion = pIdSesion;
    
    -- Crear reserva
    INSERT INTO Reservas VALUES (
        secuencia_idReserva.NEXTVAL,
        vSesion,
        vCliente,
        pFormaPago,
        pFechaCompra,
        pEntradas
    )
    RETURNING idReserva INTO vIdReserva;
    COMMIT;
    
    -- Crear asociaciones de butacas a la reserva
    FOR i IN 1..pButacas.COUNT LOOP
        SELECT REF(b) INTO vButaca FROM Butacas b 
        WHERE b.idButaca = SUBSTR(pButacas(i), 1, INSTR(pButacas(i), '-') - 1)
        AND b.NumeroSala = SUBSTR(pButacas(i), INSTR(pButacas(i), '-') + 1);

        INSERT INTO ButacasReservas VALUES (
            secuencia_idButacaReserva.NEXTVAL,
            vButaca,
            (SELECT REF(r) FROM Reservas r WHERE r.idReserva = vIdReserva)
        );
    END LOOP;
    
    COMMIT;
END RealizarReserva;
/

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

CREATE OR REPLACE PROCEDURE RegistrarCliente(
    p_nombre_cliente IN Clientes.Nombre%TYPE,
    p_correo_cliente IN Clientes.Correo%TYPE,
    p_telefono_cliente IN Clientes.Telefono%TYPE
) AS
BEGIN
    INSERT INTO Clientes (Correo, Nombre, Telefono)
    VALUES (p_correo_cliente, p_nombre_cliente, p_telefono_cliente);
    
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE ListarCliente(
    p_id_cliente IN Clientes.idCliente%TYPE
) AS
BEGIN
    SELECT Nombre, Correo, Telefono
    From Clientes
    WHERE idCliente = p_id_cliente;
END;
/

CREATE OR REPLACE PROCEDURE ModificarCliente(
    p_id_cliente IN Clientes.idCliente%TYPE,
    p_nombre_cliente IN Clientes.Nombre%TYPE,
    p_telefono_cliente IN Clientes.Telefono%TYPE
) AS
BEGIN
    UPDATE Clientes
    SET Nombre = p_nombre_cliente, Telefono = p_telefono_cliente
    WHERE Correo = p_id_cliente;
    
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE EliminarCliente(
    p_id_cliente IN Clientes.idCliente%TYPE
) AS
BEGIN
    DELETE FROM Clientes
    WHERE Correo = p_id_cliente;
    
    COMMIT;
END;
/
--Listar detalles de una película por id.
--Listar fecha de las sesiones para el id de una película (función para devolver asientos libres de una sesión).
--Fecha y hora de las sesiones con al menos un asiento disponible.
--Asientos libres y no libres de una sesión (función ?).

--Realizar reserva(cliente[nombre, correo, tlf], entradas[descripción, menú, precio], butacas[id, sala])
  -- COMPROBAR QUE EL CLIENTE EXISTE!!!! (si no, añadir cliente).
  -- Si existe, update del teléfono y el nombre.
--Eliminar reserva()
 -- 1.-Eliminar entradas
 -- 2.-Eliminar reserva_butaca
 -- 3.-Eliminar reserva

--Registrar cliente
--Listar cliente
--Modificar cliente
--Eliminar cliente


CREATE OR REPLACE PROCEDURE ListarPelicula(p_idPelicula IN Peliculas.idPelicula%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlTrailer
        FROM Peliculas
        WHERE idPelicula = p_idPelicula;
END;
/

CREATE OR REPLACE PROCEDURE ListarSesionesPelicula(p_idPelicula IN Peliculas.idPelicula%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT s.idSesion, s.NumeroSala, s.FechaHora
        FROM Sesiones s JOIN Butacas b ON s.NumeroSala = b.NumeroSala
        WHERE s.idPelicula = p_idPelicula AND b.Estado = 'Libre'
        GROUP BY s.idSesion, s.NumeroSala, s.FechaHora
        HAVING COUNT(b.idButaca) > 0;
END;
/

CREATE OR REPLACE PROCEDURE MostrarMapaButacas(p_idSesion IN Sesiones.idSesion%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT idButaca, NumeroSala, Estado
        FROM Butacas
        WHERE NumeroSala = (SELECT NumeroSala FROM Sesiones WHERE idSesion = p_idSesion);
END;
/

CREATE OR REPLACE PROCEDURE RegistrarCliente(
    p_nombre IN Clientes.Nombre%TYPE,
    p_telefono IN Clientes.Telefono%TYPE,
    p_correo IN Clientes.Correo%TYPE)
    IS
BEGIN
    INSERT INTO Clientes (idCliente, Nombre, Telefono, Correo)
    VALUES (secuencia_idCliente.NEXTVAL, p_nombre, p_telefono, p_correo);
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE ModificarCliente(
    p_idCliente IN Clientes.idCliente%TYPE,
    p_nombre IN Clientes.Nombre%TYPE,
    p_telefono IN Clientes.Telefono%TYPE,
    p_correo IN Clientes.Correo%TYPE)
    IS
BEGIN
    UPDATE Clientes
    SET Nombre = p_nombre, Telefono = p_telefono, Correo = p_correo
    WHERE idCliente = p_idCliente;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE EliminarCliente(
    p_idCliente IN Clientes.idCliente%TYPE)
    IS
BEGIN
    DELETE FROM Clientes
    WHERE idCliente = p_idCliente;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE ListarClientes(p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT idCliente, Nombre, Telefono, Correo
        FROM Clientes;
END;
/

CREATE OR REPLACE PROCEDURE ListarCliente(p_idCliente IN Clientes.idCliente%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT idCliente, Nombre, Telefono, Correo
        FROM Clientes
        WHERE idCliente = p_idCliente;
END;
/

CREATE OR REPLACE PROCEDURE RealizarReserva(
    p_idCliente IN Clientes.idCliente%TYPE,
    p_idSesion IN Sesiones.idSesion%TYPE,
    p_idButacas IN Butacas.idButaca%TYPE)
    IS
BEGIN
    INSERT INTO Reservas (idReserva, idSesion, idCliente, FechaCompra)
    VALUES (secuencia_idReserva.NEXTVAL, p_idSesion, p_idCliente, SYSDATE);

    UPDATE Butacas
    SET Estado = 'Reservada'
    WHERE idButaca = p_idButacas;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE CancelarReserva(
    p_idReserva IN Reservas.idReserva%TYPE)
    IS
BEGIN
    UPDATE Butacas
    SET Estado = 'Libre'
    WHERE idButaca IN (SELECT idButaca FROM ButacasReservas WHERE refReserva = p_idReserva);

    DELETE FROM Reservas
    WHERE idReserva = p_idReserva;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE ListarReservas(p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT r.idReserva, r.idSesion, r.idCliente, r.FechaCompra
        FROM Reservas r;
END;
/

CREATE OR REPLACE PROCEDURE ListarReserva(p_idReserva IN Reservas.idReserva%TYPE, p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT r.idReserva, r.idSesion, r.idCliente, r.FechaCompra
        FROM Reservas r
        WHERE r.idReserva = p_idReserva;
END;
/