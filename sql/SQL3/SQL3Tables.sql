-- Tabla para Peliculas
CREATE TABLE Peliculas OF TipoPelicula (
    PRIMARY KEY (idPelicula)
);

-- Tabla para Sesiones
CREATE TABLE Sesiones OF TipoSesion (
    PRIMARY KEY (idSesion)
);

-- Tabla para Butacas
CREATE TABLE Butacas OF TipoButaca (
    PRIMARY KEY (idButaca)
);

-- Tabla para Clientes
CREATE TABLE Clientes OF TipoCliente (
    PRIMARY KEY (idCliente),
    UNIQUE (Correo)  -- Suponiendo que el correo debe ser único
);

-- Tabla para Reservas
CREATE TABLE Reservas OF TipoReserva (
    PRIMARY KEY (idReserva)
);

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
    PRIMARY KEY (idButacaReserva)
);
