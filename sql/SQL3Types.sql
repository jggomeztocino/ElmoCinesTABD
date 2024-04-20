-- Tipo para Pelicula
CREATE TYPE TipoPelicula AS (
    idPelicula INTEGER,
    Titulo VARCHAR(207),
    -- Película con el título más largo:
    -- Night of the Day of the Dawn of the Son of the Bride of the Return of the Revenge of the Terror of the Attack of the Evil,
    -- Mutant, Alien, Flesh Eating, Hellbound, Zombified Living Dead Part 2 in Shocking 2-D: 207 caracteres
    Directores VARCHAR(100),
    Actores VARCHAR(100),
    Duracion INTEGER,
    Sinopsis VARCHAR(500),
    UrlTrailer VARCHAR(200)
);

-- Tipo para Sesion
CREATE TYPE TipoSesion AS (
    idSesion INTEGER,
    idPelicula REF TipoPelicula,
    NumeroSala INTEGER,
    FechaHora TIMESTAMP
);

-- Tipo para Butaca
CREATE TYPE TipoButaca AS (
    idButaca INTEGER,
    NumeroSala INTEGER,
    Estado VARCHAR(50)
);

-- Tipo para Cliente
CREATE TYPE TipoCliente AS (
    idCliente INTEGER,
    Nombre VARCHAR(100),
    Telefono VARCHAR(15),
    Correo VARCHAR(100)
);

-- Tipo para Reserva
CREATE TYPE TipoReserva AS (
    idReserva INTEGER,
    idSesion REF TipoSesion,
    idCliente REF TipoCliente,
    FormaPago VARCHAR(50),
    FechaCompra TIMESTAMP
);

-- Tipo para Entrada
CREATE TYPE TipoEntrada AS (
    idEntrada INTEGER,
    idReserva REF TipoReserva,
    idMenu REF TipoMenu,
    Descripcion VARCHAR(200),
    Precio DECIMAL(10, 2)
);

-- Tipo para Menu
CREATE TYPE TipoMenu AS (
    idMenu INTEGER,
    Descripcion VARCHAR(100),
    Precio DECIMAL(10, 2)
);

-- Tipo para la asociación N:M entre Butaca y Reserva
CREATE TYPE TipoButacaReserva AS (
    idButacaReserva INTEGER,
    refButaca REF TipoButaca,
    refReserva REF TipoReserva
);
