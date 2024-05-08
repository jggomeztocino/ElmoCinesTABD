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
            IF SesionesPkg.calcular_butacas_libres(:NEW.idSesion) = 0 THEN
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
    default_menu EXCEPTION;
    v_entradas TipoEntradaArray;
    -- Las colecciones de objetos no pueden ser modificadas directamente, por lo que se crea esta variable auxiliar
BEGIN
    IF :OLD.idMenu = 0 THEN
        RAISE default_menu;
    ELSE
        FOR r IN (SELECT r.rowid AS rid, r.Entradas
                  FROM Reservas r
                  WHERE EXISTS (SELECT 1 FROM TABLE(r.Entradas) e WHERE e.idMenu = :OLD.idMenu))
        LOOP
            v_entradas := r.Entradas;
            FOR i IN 1..v_entradas.COUNT LOOP
                IF v_entradas(i).idMenu = :OLD.idMenu THEN
                    v_entradas(i) := TipoEntrada(v_entradas(i).idEntrada, 'Sin menú', 0, 0);
                END IF;
            END LOOP;
            -- Actualizar la reserva con el nuevo array de entradas modificado
            UPDATE Reservas SET Entradas = v_entradas WHERE rowid = r.rid;
        END LOOP;
    END IF;
EXCEPTION
    WHEN default_menu THEN
        RAISE_APPLICATION_ERROR(-20003, 'No se puede borrar el menú por defecto.');
END;
/


COMMIT;