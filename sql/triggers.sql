--Disparador que comprueba si, al realizar una reserva, el cliente existe o no.
CREATE OR REPLACE TRIGGER Trg_VerificarCliente
BEFORE INSERT ON Reservas
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM Clientes WHERE Correo = :NEW.idCliente.Correo;
    --Si el cliente no existe, se registrarÃ¡ en la base de datos.
    IF v_count = 0 THEN
        INSERT INTO Clientes (Correo, Nombre, Telefono)
        VALUES (:NEW.idCliente.Correo, :NEW.idCliente.Nombre, :NEW.idCliente.Telefono);
    --En caso contrario, se actualizarÃ¡n su nombre y nÃºmero de telÃ©fono.
    ELSE
        UPDATE Clientes
        SET Nombre = :NEW.idCliente.Nombre, Telefono = :NEW.idCliente.Telefono
        WHERE Correo = :NEW.idCliente.Correo;
    END IF;
END;
/

--Disparador que elimina las butacas y reservas de un cliente, al darse de baja en la aplicaciÃ³n.
CREATE OR REPLACE TRIGGER Trg_EliminarCliente
BEFORE DELETE ON Clientes
FOR EACH ROW
BEGIN
    DELETE FROM ButacasReservas WHERE refReserva IN (SELECT REF(r) FROM Reservas r WHERE r.idCliente.Correo = :OLD.Correo);
    DELETE FROM Reservas WHERE idCliente = :OLD.Correo;
END;
/

--Disparador que comprueba si las butacas seleccionadas por el usuario siguen libres al realizar la reserva.
CREATE OR REPLACE TRIGGER Trg_VerificarButacas
BEFORE INSERT ON Reservas
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM ButacasReservas
    WHERE idButaca IN (SELECT COLUMN_VALUE FROM TABLE(:NEW.Entradas.idButaca))
      AND refReserva IS NOT NULL;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Una o mÃ¡s butacas ya estÃ¡n reservadas.');
    END IF;
END;
/

--Disparador que elimina las butacas y entradas de una reserva, al ser esta eliminada.
CREATE OR REPLACE TRIGGER Trg_EliminarReserva
BEFORE DELETE ON Reservas
FOR EACH ROW
BEGIN
    DELETE FROM ButacasReservas WHERE refReserva = :OLD.idReserva;
    DELETE FROM Entradas WHERE idReserva = :OLD.idReserva;
END;
/

DELETE FROM Clientes WHERE Correo = 'stephen.eason@guest.elmocines.com';

DECLARE
    pCorreo CLIENTES.CORREO%TYPE := 'aaron.cotton@guest.elmocines.com';
    pNombre CLIENTES.NOMBRE%TYPE := 'Carlito';
    pTelefono CLIENTES.TELEFONO%TYPE := '4564567890';
    pIdSesion SESIONES.IDSESION%TYPE := 5;  -- Asegúrate de que esta sesión exista
    pFormaPago RESERVAS.FORMAPAGO%TYPE := 'Tarjeta de crédito';
    pFechaCompra TIMESTAMP := SYSTIMESTAMP;
    pButacas SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('1-2', '2-2');  -- Corrige a los IDs de butaca correctos si es necesario
    pEntradas TipoEntradaArray;
    refMenu1 REF TipoMenu;
    refMenu2 REF TipoMenu;
BEGIN
    -- Obtener las referencias de los menús
    SELECT REF(m) INTO refMenu1 FROM Menus m WHERE m.idMenu = 1;
    SELECT REF(m) INTO refMenu2 FROM Menus m WHERE m.idMenu = 2;

    -- Inicializar el array de entradas
    pEntradas := TipoEntradaArray();
    pEntradas.EXTEND(2);
    pEntradas(1) := TipoEntrada(1, refMenu1, 'Combo Palomitas', 5.00);
    pEntradas(2) := TipoEntrada(2, refMenu2, 'Refresco Grande', 3.00);

    -- Llamada al procedimiento para realizar la reserva
    RealizarReserva(pCorreo, pNombre, pTelefono, pIdSesion, pFormaPago, pFechaCompra, pButacas, pEntradas);
    COMMIT;  -- Confirmar la transacción si todo ha sido procesado correctamente
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al realizar la reserva: ' || SQLERRM);
        ROLLBACK;  -- Revertir la transacción en caso de error
END;