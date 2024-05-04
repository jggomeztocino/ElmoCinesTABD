--Disparador que comprueba si, al realizar una reserva, el cliente existe o no.
CREATE OR REPLACE TRIGGER Trg_VerificarCliente
BEFORE INSERT ON Reservas
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Acceder al objeto referenciado
    SELECT COUNT(*) INTO v_count FROM Clientes WHERE Correo = DEREF(:NEW.idCliente).Correo;

    -- Si el cliente no existe, se registrará en la base de datos.
    IF v_count = 0 THEN
        -- Insertar el nuevo cliente
        INSERT INTO Clientes (Correo, Nombre, Telefono)
        VALUES (DEREF(:NEW.idCliente).Correo, DEREF(:NEW.idCliente).Nombre, DEREF(:NEW.idCliente).Telefono);
    -- En caso contrario, se actualizarán su nombre y número de teléfono.
    ELSE
        -- Actualizar el cliente existente
        UPDATE Clientes
        SET Nombre = DEREF(:NEW.idCliente).Nombre, Telefono = DEREF(:NEW.idCliente).Telefono
        WHERE Correo = DEREF(:NEW.idCliente).Correo;
    END IF;
END;
/

--Disparador que elimina las butacas y reservas de un cliente, al darse de baja en la aplicaciÃ³n.
CREATE OR REPLACE TRIGGER Trg_EliminarCliente
BEFORE DELETE ON Clientes
FOR EACH ROW
BEGIN
    -- Eliminar las relaciones de ButacasReservas asociadas al cliente que está siendo eliminado
    DELETE FROM ButacasReservas WHERE refReserva IN (SELECT REF(r) FROM Reservas r WHERE DEREF(r.idCliente).Correo = :OLD.Correo);
    
    -- Eliminar las reservas asociadas al cliente que está siendo eliminado
    DELETE FROM Reservas WHERE idCliente = (SELECT REF(c) FROM Clientes c WHERE c.Correo = :OLD.Correo);
END;
/

CREATE OR REPLACE FUNCTION get_ref_butaca(p_ref_butaca REF TipoButaca)
  RETURN TipoButaca
AS
  v_butaca TipoButaca;
BEGIN
  SELECT DEREF(p_ref_butaca) INTO v_butaca FROM DUAL;
  RETURN v_butaca;
END;
/

--Disparador que comprueba si las butacas seleccionadas por el usuario siguen libres al realizar la reserva.
CREATE OR REPLACE TRIGGER Trg_VerificarButacas
BEFORE INSERT ON Reservas
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ButacasReservas br
    WHERE br.refReserva IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM TABLE(:NEW.Entradas) e
        WHERE br.refButaca = e.idButaca
    );

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Una o más butacas ya están reservadas.');
    END IF;
END;
/

--Disparador que elimina las butacas y entradas de una reserva, al ser esta eliminada.
CREATE OR REPLACE TRIGGER Trg_EliminarReserva
BEFORE DELETE ON Reservas
FOR EACH ROW
BEGIN
    -- Eliminar las relaciones de ButacasReservas asociadas a la reserva
    FOR b IN (SELECT refButaca FROM ButacasReservas WHERE refReserva = :OLD.idReserva) LOOP
        DELETE FROM ButacasReservas WHERE refButaca = b.refButaca AND refReserva = :OLD.idReserva;
    END LOOP;

    
END;
/