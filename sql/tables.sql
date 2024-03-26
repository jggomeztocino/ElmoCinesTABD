-- Eliminación de tablas si existen
BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Reservas CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
END IF;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Sesiones CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
END IF;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Butacas CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
END IF;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Peliculas CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
END IF;
END;
/

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE TiposEntrada CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
END IF;
END;

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE Menus CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
END IF;
END;

-- Creación de tablas
CREATE TABLE Peliculas (
                           idPelicula VARCHAR2(20) PRIMARY KEY,
                           titulo VARCHAR2(100) NOT NULL,
                           directores VARCHAR2(200) NOT NULL,
                           actores VARCHAR2(300) NOT NULL,
                           duracion NUMBER NOT NULL,
                           sinopsis CLOB NOT NULL,
                           urlTrailer VARCHAR2(300) NOT NULL
);

CREATE TABLE Sesiones (
                          idSesion NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                          idPelicula VARCHAR2(20) NOT NULL,
                          nSala NUMBER NOT NULL,
                          fechaHora DATE NOT NULL, -- De aquí, desglosaremos la fecha y la hora
                          FOREIGN KEY (idPelicula) REFERENCES Peliculas(idPelicula)
);

CREATE TABLE Butacas (
                         idButaca NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         descripcion VARCHAR2(50) NOT NULL
);

CREATE TABLE TiposEntrada (
                              idTipoEntrada NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                              descripcion VARCHAR2(100) NOT NULL,
                              precio NUMBER NOT NULL
);

CREATE TABLE Menus (
                       idMenu NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                       descripcion VARCHAR2(100) NOT NULL,
                       precio NUMBER NOT NULL
);


CREATE TABLE Reservas (
                          idReserva NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                          idSesion NUMBER NOT NULL,
                          idButaca NUMBER NOT NULL,
                          idTipoEntrada NUMBER NOT NULL,
                          idMenu NUMBER,
                          nombreComprador VARCHAR2(100) NOT NULL,
                          fechaCompra DATE NOT NULL,
                          UNIQUE (idSesion, idButaca),
                          FOREIGN KEY (idSesion) REFERENCES Sesiones(idSesion),
                          FOREIGN KEY (idButaca) REFERENCES Butacas(idButaca),
                          FOREIGN KEY (idTipoEntrada) REFERENCES TiposEntrada(idTipoEntrada),
                          FOREIGN KEY (idMenu) REFERENCES Menus(idMenu)
);