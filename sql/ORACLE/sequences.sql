-- Secuencia para la tabla Sesiones
CREATE SEQUENCE secuencia_idSesion
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/

-- Secuencia cíclica para la tabla Butacas
CREATE SEQUENCE secuencia_idButaca
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 30
    MINVALUE 1
    CYCLE
    NOCACHE;
/

-- Secuencia para la tabla Reservas
CREATE SEQUENCE secuencia_idReserva
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/

-- Secuencia para la tabla Entradas
CREATE SEQUENCE secuencia_idEntrada
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/

-- Secuencia para la tabla Menús
CREATE SEQUENCE secuencia_idMenu
    START WITH 0
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/

-- Secuencia para la tabla ButacasReservas
CREATE SEQUENCE secuencia_idButacaReserva
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;
/
COMMIT;