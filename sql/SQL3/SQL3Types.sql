-- Tipo para Pelicula
CREATE TYPE TipoPelicula AS (
    idPelicula VARCHAR(20),
    Titulo VARCHAR(200),
    Directores VARCHAR(200),
    Actores VARCHAR(400),
    Duracion INTEGER,
    Sinopsis VARCHAR(500),
    UrlCover VARCHAR(200),
    UrlTrailer VARCHAR(200)
);

-- Tipo para Sesion
CREATE TYPE TipoSesion AS (
    idSesion INTEGER,
    --idPelicula REF TipoPelicula,
    idPelicula VARCHAR(20),
    NumeroSala INTEGER,
    FechaHora TIMESTAMP
);

-- Tipo para Butaca
CREATE TYPE TipoButaca AS (
    idButaca INTEGER,
    NumeroSala INTEGER
);

-- Tipo para Cliente
CREATE TYPE TipoCliente AS (
    Correo VARCHAR(100),
    Nombre VARCHAR(100),
    Telefono VARCHAR(15)
);

-- Tipo para Menu
CREATE TYPE TipoMenu AS (
    idMenu INTEGER,
    Descripcion VARCHAR(200),
    Precio DECIMAL(10, 2)
);

-- Tipo para Entrada
CREATE TYPE TipoEntrada AS (
    idEntrada INTEGER,
    --idMenu REF TipoMenu,
    idMenu INTEGER,
    Descripcion VARCHAR(200),
    Precio DECIMAL(10, 2)
);

-- Tipo para Reserva
CREATE TYPE TipoReserva AS (
    idReserva INTEGER,
    --idSesion REF TipoSesion,
    --idCliente REF TipoCliente,
    idSesion INTEGER,
    Cliente VARCHAR(100),
    FormaPago VARCHAR(50),
    FechaCompra TIMESTAMP,
    Entradas TipoEntrada ARRAY(5)
);

-- Tipo para la asociación N:M entre Butaca y Reserva
CREATE TYPE TipoButacaReserva AS (
    idButacaReserva INTEGER,
    --refButaca REF TipoButaca,
    --refReserva REF TipoReserva
    idButaca INTEGER,
    NumeroSala INTEGER,
    idReserva INTEGER
);
