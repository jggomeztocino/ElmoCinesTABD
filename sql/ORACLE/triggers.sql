-- Trigger para garantizar la integridad referencial entre Entradas y Menús
CREATE OR REPLACE TRIGGER verificar_menu_entrada
    BEFORE INSERT OR UPDATE OF Entradas ON Reservas
    FOR EACH ROW
DECLARE
    existencia_menu NUMBER;
BEGIN
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

-- Disparador para liberar butacas antes de eliminar una reserva
CREATE OR REPLACE TRIGGER liberar_butacas
    BEFORE DELETE ON Reservas
    FOR EACH ROW
BEGIN
    DELETE FROM ButacasReservas
    WHERE idReserva = :OLD.idReserva;
END;
/

-- Disparador para eliminar todas las reservas asociadas antes de eliminar un cliente
CREATE OR REPLACE TRIGGER borrar_reservas_cliente
    BEFORE DELETE ON Clientes
    FOR EACH ROW
BEGIN
    FOR rec IN (SELECT idReserva FROM Reservas WHERE Cliente = :OLD.Correo)
        LOOP
            -- Antes de borrar la reserva, se eliminan las butacas asociadas (Disparador)
            DELETE FROM Reservas
            WHERE idReserva = rec.idReserva;
        END LOOP;
END;
/

-- Disparador para eliminar todas las reservas de una sesión antes de eliminar la sesión
CREATE OR REPLACE TRIGGER borrar_reservas_sesion
    BEFORE DELETE ON Sesiones
    FOR EACH ROW
BEGIN
    FOR rec IN (SELECT idReserva FROM Reservas WHERE idSesion = :OLD.idSesion)
        LOOP
            -- Antes de borrar la reserva, se eliminan las butacas asociadas (Disparador)
            DELETE FROM Reservas
            WHERE idReserva = rec.idReserva;
        END LOOP;
END;

-- Disparador para borrar el cliente si se repite el correo (Dejamos solo el registro actualizado: nueva inserción)
CREATE OR REPLACE TRIGGER existe_cliente
    BEFORE INSERT ON Clientes
    FOR EACH ROW
DECLARE
    cliente_repetido EXCEPTION;
BEGIN
    IF (SELECT COUNT(*)
        FROM Clientes
        WHERE Correo = :NEW.Correo) > 0 THEN
        RAISE cliente_repetido;
    END IF;
EXCEPTION
    WHEN cliente_repetido THEN
        -- Si el cliente ya existe, se actualiza su información
        DELETE FROM Clientes
        WHERE Correo = :NEW.Correo;
END;
/

-- Disparador para, cuando se borra una película, borrar todas las sesiones, reservas y butacas asociadas
CREATE OR REPLACE TRIGGER borrar_pelicula
    BEFORE DELETE ON Peliculas
    FOR EACH ROW
BEGIN
    FOR rec IN (SELECT idSesion FROM Sesiones WHERE idPelicula = :OLD.idPelicula)
        LOOP
            -- Antes de borrar la sesión, se eliminan las reservas asociadas (Disparador)
            DELETE FROM Sesiones
            WHERE idSesion = rec.idSesion;
        END LOOP;
END;
/

-- Disparador para, cuando se borra un menú:
-- 1. Compruebe que no es el menu 0 (Menú por defecto: Sin menú)
-- 2. Si no es el menú 0, cambie todas las reservas que lo tengan por el menú 0
CREATE OR REPLACE TRIGGER borrar_menu
    BEFORE DELETE ON Menus
    FOR EACH ROW
DECLARE
    menu_por_defecto EXCEPTION;
BEGIN
    IF :OLD.idMenu = 0 THEN
        RAISE menu_por_defecto;
    ELSE
        UPDATE Reservas
        SET Entradas = TipoEntradaArray(TipoEntrada(0, 'Sin menú', 0))
        WHERE EXISTS (SELECT 1
                      FROM TABLE(Entradas) e
                      WHERE e.idMenu = :OLD.idMenu);
    END IF;
EXCEPTION
    WHEN menu_por_defecto THEN
        RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar el menú por defecto.');
END;