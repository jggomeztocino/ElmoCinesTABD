-- Tipo para Película
CREATE OR REPLACE TYPE TipoPelicula AS OBJECT (
    idPelicula VARCHAR2(20),
    Titulo VARCHAR2(200),
    Directores VARCHAR2(200),
    Actores VARCHAR2(400),
    Duracion NUMBER(3),
    Sinopsis VARCHAR2(500),
    UrlCover VARCHAR2(200),
    UrlTrailer VARCHAR2(200)
);
/

-- Tipo para Sesión
CREATE OR REPLACE TYPE TipoSesion AS OBJECT (
    idSesion NUMBER,
    idPelicula REF TipoPelicula,
    NumeroSala NUMBER(2),
    FechaHora TIMESTAMP
);
/

-- Tipo para Butaca
CREATE OR REPLACE TYPE TipoButaca AS OBJECT (
    idButaca NUMBER,
    NumeroSala NUMBER(2)
);
/

-- Tipo para Cliente
CREATE OR REPLACE TYPE TipoCliente AS OBJECT (
    Correo VARCHAR2(100),
    Nombre VARCHAR2(100),
    Telefono VARCHAR2(15)
);
/

-- Tipo para Menú
CREATE OR REPLACE TYPE TipoMenu AS OBJECT (
    idMenu NUMBER,
    Descripcion VARCHAR2(200),
    Precio NUMBER(10, 2)
);
/

-- Tipo para Entrada
CREATE OR REPLACE TYPE TipoEntrada AS OBJECT (
    idEntrada NUMBER,
    idMenu REF TipoMenu,
    Descripcion VARCHAR2(200),
    Precio NUMBER(10, 2)
);
/

-- Crear un tipo de tabla para las entradas
CREATE OR REPLACE TYPE TablaEntradas AS TABLE OF TipoEntrada;
/

-- Tipo para Reserva
CREATE OR REPLACE TYPE TipoReserva AS OBJECT (
    idReserva NUMBER,
    idSesion REF TipoSesion,
    idCliente REF TipoCliente,
    FormaPago VARCHAR2(50),
    FechaCompra TIMESTAMP,
    Entradas TablaEntradas  -- Campo de NESTED TABLE para la composición de entradas
);
/

-- Tipo para la asociación N:M entre Butaca y Reserva
CREATE OR REPLACE TYPE TipoButacaReserva AS OBJECT (
    idButacaReserva NUMBER,
    refButaca REF TipoButaca,
    refReserva REF TipoReserva
);
/
COMMIT;