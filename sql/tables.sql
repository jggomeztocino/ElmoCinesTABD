-- Tabla para Películas
CREATE TABLE Peliculas OF TipoPelicula (
                                           CONSTRAINT PK_Peliculas PRIMARY KEY (idPelicula)
)
    PCTFREE 10  -- Reserva un 10% del espacio de cada bloque para futuras actualizaciones de las filas.
    PCTUSED 70  -- Permite que un bloque se considere disponible para nuevas inserciones solo cuando el 70% de su espacio está libre.
    INITRANS 2  -- Establece el número inicial de transacciones concurrentes posibles por bloque.
    MAXTRANS 255  -- Permite un máximo de 255 transacciones concurrentes por bloque.
    NOCACHE;  -- No utiliza la caché de secuencias para la generación de IDs, dado que no esperamos un volumen muy alto de inserciones rápidas.
/

-- Tabla para Sesiones
CREATE TABLE Sesiones OF TipoSesion (
                                        CONSTRAINT PK_Sesiones PRIMARY KEY (idSesion)
)
    PCTFREE 10
    PCTUSED 80  -- Aumenta el umbral de uso debido a que las sesiones pueden cambiar frecuentemente, especialmente las horas.
    INITRANS 3  -- Incrementa para permitir más transacciones concurrentes, útil en ventas de entradas de última hora.
    MAXTRANS 255
    NOCACHE;
/

ALTER TABLE Sesiones MODIFY idPelicula NOT NULL;
ALTER TABLE Sesiones ADD (SCOPE FOR (idPelicula) IS Peliculas);

-- Tabla para Butacas
CREATE TABLE Butacas OF TipoButaca (
                                       CONSTRAINT PK_Butacas PRIMARY KEY (idButaca, NumeroSala)
)
    PCTFREE 5  -- Menor reserva de espacio libre debido a la baja frecuencia de actualización.
    PCTUSED 90  -- Las butacas no cambian de estado con alta frecuencia, permitiendo un umbral más alto.
    INITRANS 1  -- Bajas transacciones concurrentes.
    MAXTRANS 100
    CACHE;  -- Puede beneficiarse de la caché si el estado de las butacas se consulta frecuentemente.
/

-- Tabla para Clientes
CREATE TABLE Clientes OF TipoCliente (
                                         CONSTRAINT PK_Clientes PRIMARY KEY (Correo)
)
PCTFREE 15  -- Más espacio para actualizaciones ya que los datos de clientes pueden cambiar (p. ej., cambio de número de teléfono).
PCTUSED 75
INITRANS 4  -- Preparado para un número moderado de transacciones concurrentes, dado que el cliente puede hacer múltiples reservas a la vez.
MAXTRANS 200
NOCACHE;
/

-- Tabla para Reservas
CREATE TABLE Reservas OF TipoReserva (
                                         CONSTRAINT PK_Reservas PRIMARY KEY (idReserva)
) NESTED TABLE Entradas STORE AS Tabla_Entradas
    PCTFREE 20  -- Alto porcentaje de espacio libre para permitir modificaciones en las reservas.
    PCTUSED 60  -- Bajo umbral de uso para garantizar un rendimiento eficiente en la inserción.
    INITRANS 5  -- Alto número de transacciones iniciales para manejar picos de reservas.
    MAXTRANS 255
    NOCACHE;
/

ALTER TABLE Reservas MODIFY idSesion NOT NULL;
ALTER TABLE Reservas MODIFY idCliente NOT NULL;
ALTER TABLE Reservas ADD (SCOPE FOR (idSesion) IS Sesiones);
ALTER TABLE Reservas ADD (SCOPE FOR (idCliente) IS Clientes);

-- Tabla para Menús
CREATE TABLE Menus OF TipoMenu (
                                   CONSTRAINT PK_Menus PRIMARY KEY (idMenu)
)
    PCTFREE 5  -- Menor reserva de espacio libre, ya que los menús tienden a no cambiar frecuentemente.
    PCTUSED 90  -- Permite un alto grado de llenado antes de considerar el bloque lleno.
    INITRANS 2  -- Menos transacciones concurrentes necesarias.
    MAXTRANS 100
    NOCACHE;  -- Los cambios son infrecuentes y no se benefician significativamente de la caché.
/

ALTER TABLE Tabla_Entradas ADD (SCOPE FOR (idMenu) IS Menus);
ALTER TABLE Tabla_Entradas
    PCTFREE 10
    PCTUSED 70
    INITRANS 10  -- Incrementado para gestionar altos volúmenes de transacciones durante períodos de ventas intensas.
    MAXTRANS 255
    NOCACHE;

-- Tabla para Entradas
CREATE TABLE Entradas OF TipoEntrada (
                                         CONSTRAINT PK_Entradas PRIMARY KEY (idEntrada)
)
    PCTFREE 10
    PCTUSED 85  -- Se espera que las entradas se llenen y cambien de estado a un ritmo moderado, especialmente en días de estreno.
    INITRANS 4  -- Esperamos algunas transacciones concurrentes, especialmente durante la venta de entradas de alto perfil.
    MAXTRANS 255
    NOCACHE;  -- No es crítico cachear, dado que la creación de IDs no necesita un alto rendimiento.
/

ALTER TABLE Entradas ADD (SCOPE FOR (idMenu) IS Menus);

-- Tabla para gestionar las relaciones N:M entre Butacas y Reservas
CREATE TABLE ButacasReservas OF TipoButacaReserva (
                                                      CONSTRAINT PK_ButacasReservas PRIMARY KEY (idButacaReserva)
)
    PCTFREE 20  -- Se necesita más espacio libre para ajustes, dado que las asignaciones de butacas a reservas pueden cambiar con cancelaciones y reasignaciones.
    PCTUSED 50  -- Un umbral bajo para asegurar que los bloques se mantengan disponibles para nuevas asignaciones rápidamente.
    INITRANS 6  -- Puede requerir un alto nivel de concurrencia, especialmente en días de estreno o eventos especiales.
    MAXTRANS 255
    NOCACHE;  -- La asignación de butacas puede beneficiarse de una rápida accesibilidad sin necesidad de caché.
/

ALTER TABLE ButacasReservas ADD (SCOPE FOR (refButaca) IS Butacas);
ALTER TABLE ButacasReservas ADD (SCOPE FOR (refReserva) IS Reservas);

ALTER TABLE ButacasReservas MODIFY refButaca NOT NULL;
ALTER TABLE ButacasReservas MODIFY refReserva NOT NULL;

COMMIT;