-- Trigger para garantizar la integridad referencial entre Entradas y Menús
CREATE OR REPLACE TRIGGER verificar_menu_entrada
    BEFORE INSERT OR UPDATE OF Entradas ON Reservas
    FOR EACH ROW
DECLARE
    existencia_menu NUMBER;
BEGIN
    -- Verificar si el idMenu en cada entrada de la reserva existe en la tabla Menus
    FOR i IN 1..:NEW.Entradas.COUNT LOOP
            SELECT COUNT(*)
            INTO existencia_menu
            FROM Menus
            WHERE idMenu = :NEW.Entradas(i).idMenu;

            IF existencia_menu = 0 THEN
                -- Si no existe, levanta un error
                RAISE_APPLICATION_ERROR(-20001, 'El menú con ID ' || TO_CHAR(:NEW.Entradas(i).idMenu) || ' no existe.');
            END IF;
        END LOOP;
END;
/

-- Disparador para verificar y actualizar o insertar cliente antes de reservar
CREATE OR REPLACE TRIGGER existe_cliente
    BEFORE INSERT OR UPDATE ON Clientes
    FOR EACH ROW
DECLARE
    cliente_existente NUMBER;
BEGIN
    -- Verificar si el cliente ya existe
    SELECT COUNT(*)
    INTO cliente_existente
    FROM Clientes
    WHERE Correo = :NEW.Correo;

    IF cliente_existente = 0 THEN
        -- Si el cliente no existe, insertar un nuevo cliente
        INSERT INTO Clientes (Correo, Nombre, Telefono)
        VALUES (:NEW.Correo, :NEW.Nombre, :NEW.Telefono);
    ELSE
        -- Si el cliente existe, actualizar su información
        UPDATE Clientes
        SET Nombre = :NEW.Nombre, Telefono = :NEW.Telefono
        WHERE Correo = :NEW.Correo;
    END IF;
END;
/

-- Disparador para verificar la disponibilidad de butacas antes de registrar una reserva
CREATE OR REPLACE TRIGGER disponibilidad_butacas
    BEFORE INSERT ON Reservas
    FOR EACH ROW
DECLARE
    butaca_ocupada EXCEPTION;
BEGIN
    -- Verificar la disponibilidad de las butacas
    FOR i IN 1..:NEW.Entradas.COUNT LOOP
            IF calcular_butacas_libres(:NEW.idSesion) = 0 THEN
                RAISE butaca_ocupada;
            END IF;
        END LOOP;
EXCEPTION
    WHEN butaca_ocupada THEN
        RAISE_APPLICATION_ERROR(-20002, 'Butaca no disponible.');
END;
/

-- Disparador para eliminar todas las entradas asociadas y liberar butacas antes de eliminar una reserva
CREATE OR REPLACE TRIGGER borrar_entradasybutacas_reserva
    BEFORE DELETE ON Reservas
    FOR EACH ROW
BEGIN
    -- Liberar las butacas reservadas
    DELETE FROM ButacasReservas
    WHERE idReserva = :OLD.idReserva;
END;
/

-- Disparador para eliminar todas las reservas de un cliente y liberar butacas antes de eliminar el cliente
CREATE OR REPLACE TRIGGER borrar_reservas_cliente
    BEFORE DELETE ON Clientes
    FOR EACH ROW
BEGIN
    -- Eliminar todas las reservas asociadas al cliente
    FOR rec IN (SELECT idReserva FROM Reservas WHERE Cliente = :OLD.Correo)
        LOOP
            DELETE FROM ButacasReservas
            WHERE idReserva = rec.idReserva;

            DELETE FROM Reservas
            WHERE idReserva = rec.idReserva;
        END LOOP;
END;
/