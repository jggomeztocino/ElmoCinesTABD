CREATE OR REPLACE PROCEDURE ListarCartelera(p_cursor OUT SYS_REFCURSOR)
    IS
BEGIN
    OPEN p_cursor FOR
        SELECT Titulo, UrlCover
        FROM Peliculas;
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