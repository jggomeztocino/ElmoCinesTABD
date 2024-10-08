-- Tabla para Peliculas
CREATE TABLE Peliculas OF TipoPelicula (
    PRIMARY KEY (idPelicula)
);

-- Tabla para Sesiones
CREATE TABLE Sesiones OF TipoSesion (
    PRIMARY KEY (idSesion),
    FOREIGN KEY (idPelicula) REFERENCES Peliculas(idPelicula)
);

ALTER TABLE Sesiones MODIFY idPelicula NOT NULL;

-- Tabla para Butacas
CREATE TABLE Butacas OF TipoButaca (
    PRIMARY KEY (idButaca)
);

-- Tabla para Clientes
CREATE TABLE Clientes OF TipoCliente (
    PRIMARY KEY (Correo)
);

-- Tabla para Reservas
CREATE TABLE Reservas OF TipoReserva (
    PRIMARY KEY (idReserva),
    FOREIGN KEY (idSesion) REFERENCES Sesiones(idSesion),
    FOREIGN KEY (Cliente) REFERENCES Clientes(Correo)
);

ALTER TABLE Reservas MODIFY idSesion NOT NULL;
ALTER TABLE Reservas MODIFY Cliente NOT NULL;

-- Tabla para Entradas
CREATE TABLE Entradas OF TipoEntrada (
    PRIMARY KEY (idEntrada)
);

-- Tabla para Menus
CREATE TABLE Menus OF TipoMenu (
    PRIMARY KEY (idMenu)
);

-- Tabla para gestionar las relaciones N:M entre Butacas y Reservas
CREATE TABLE ButacasReservas OF TipoButacaReserva (
    PRIMARY KEY (idButacaReserva),
    FOREIGN KEY (idButaca, NumeroSala) REFERENCES Butacas(idButaca, NumeroSala),
    FOREIGN KEY (idReserva) REFERENCES Reservas(idReserva)
);

ALTER TABLE ButacasReservas MODIFY idButaca NOT NULL;
ALTER TABLE ButacasReservas MODIFY NumeroSala NOT NULL;
ALTER TABLE ButacasReservas MODIFY idReserva NOT NULL;
