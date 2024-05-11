import random
from datetime import datetime, timedelta
import names  # https://pypi.org/project/names/

def generar_butacas(nButacas, sala):
     sql = []
     for _ in range(1, nButacas + 1):
         sql.append(f"INSERT INTO Butacas (idButaca, NumeroSala) VALUES (secuencia_idButaca.NEXTVAL, {sala});")
     return sql

def generar_cliente(sql):
    nombre = names.get_full_name()
    email = f"{nombre.replace(' ', '.').lower()}@guest.elmocines.com"
    telefono = f"6{random.randint(600000000, 699999999)}"
    cliente = {"Nombre": nombre, "Email": email, "Telefono": telefono}
    ##sql.append(f"INSERT INTO Clientes (Correo, Nombre, Telefono) VALUES ('{email}', '{nombre}', '{telefono}');")
    sql.append(f"EXECUTE ClientesPkg.InsertOrUpdateCliente('{email}', '{nombre}', '{telefono}');")
    sql.append(f"COMMIT;")
    return cliente, sql

def generar_entrada():
    idEntrada = f"secuencia_idEntrada.NEXTVAL"
    idMenu = random.choice([1,2,3,4,0])
    Descripcion = random.choice(["Entrada adulta", "Entrada infantil"])
    Precio = 6 if Descripcion == "Entrada adulta" else 4
    entrada = {"idEntrada": idEntrada, "idMenu": idMenu, "Descripcion": Descripcion, "Precio": Precio}
    return entrada

def generar_reservaButaca(sql, idButaca, NumeroSala):
    idButacaReserva = f"secuencia_idButacaReserva.NEXTVAL"
    sql.append(f"INSERT INTO ButacasReservas (idButacaReserva, idButaca, NumeroSala, idReserva) VALUES ({idButacaReserva}, {idButaca}, {NumeroSala}, secuencia_idReserva.CURRVAL);")
    sql.append(f"COMMIT;")
    return sql

def generar_reserva(sql, butaca, NumeroSala):
    cliente, sql = generar_cliente(sql)
    idReserva = f"secuencia_idReserva.NEXTVAL" 
    idSesion = f"secuencia_idSesion.CURRVAL"
    idCliente = cliente["Email"]
    FormaPago = random.choice(["Efectivo", "Tarjeta"])
    FechaCompra = f"TO_TIMESTAMP('{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"
    entrada = generar_entrada()
    sql.append(f"INSERT INTO Reservas (idReserva, idSesion, Cliente, FormaPago, FechaCompra, Entradas) VALUES ({idReserva}, {idSesion}, '{idCliente}', '{FormaPago}', {FechaCompra}, TipoEntradaArray(TipoEntrada({entrada['idEntrada']}, {entrada['idMenu']}, '{entrada['Descripcion']}', {entrada['Precio']})));")
    sql.append(f"COMMIT;")
    sql = generar_reservaButaca(sql, butaca, NumeroSala)
    return sql

def generar_sesiones(sesiones_dia, hora_inicio, fecha_inicio, fecha_fin, salas, nButacas, peliculas):
    sql = []
    minutos = [0, 15, 30, 45]

    for pelicula in peliculas:
        fecha_actual = fecha_inicio
        while(fecha_actual < fecha_fin):
            if random.random() <= 0.5:
                hora_actual = hora_inicio
                for _ in range(1, sesiones_dia + 1):
                    idSesion = f"secuencia_idSesion.NEXTVAL"
                    NumeroSala = random.randint(1, salas)
                    FechaHora = f"TO_TIMESTAMP('{fecha_actual.strftime('%Y-%m-%d')} {hora_actual}:{minutos[random.randint(0, 3)]}:00', 'YYYY-MM-DD HH24:MI:SS')"
                    sql.append(f"INSERT INTO Sesiones (idSesion, idPelicula, NumeroSala, FechaHora) VALUES ({idSesion}, '{pelicula}', {NumeroSala}, {FechaHora});")
                    sql.append(f"COMMIT;")
                    for butaca in range(1, nButacas + 1):
                        if random.random() <= probabilidad_ocupado:
                            sql = generar_reserva(sql, butaca, NumeroSala)
                    hora_actual += 3
                    if hora_actual >= 24:
                        hora_actual = 0
            fecha_actual += timedelta(days=1)
    return sql


# Ajusta el código de uso según los cambios
fecha_inicio = datetime(2024, 6, 1)
fecha_fin = datetime(2024, 6, 30)
salas = 8
nButacas = 30
sesiones_dia = 5
hora_inicio = 15  # Hora de inicio base de las sesiones (15:00)
probabilidad_ocupado = 0.1

peliculas = ['argylle', 'dune', 'dune2', 'kung_fu_panda_4', 'madame_web', 'one_love', 'wicked', 'wonka']

sql = []

sql.append("-- Tipos")
sql.append(f"@types.sql")

sql.append("-- Tablas")
sql.append(f"@tables.sql")

sql.append("-- Secuencias")
sql.append(f"@sequences.sql")

sql.append("-- Paquetes")
sql.append(f"@packages.sql")

sql.append("-- Triggers")
sql.append(f"@triggers.sql")

sql.append("-- Películas")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('argylle', 'Argylle', 'Matthew Vaughn', 'Henry Cavill, Bryce Dallas Howard, Sam Rockwell, Bryan Cranston, Catherine O’Hara, Dua Lipa, Ariana DeBose, John Cena, Samuel L. Jackson', 139, 'Cuando las tramas de sus libros empiezan a parecerse demasiado a las actividades de un siniestro sindicato clandestino, la introvertida autora de novelas de espías Elly Conway y su gato se ven inmersos en el verdadero mundo del espionaje…, donde nada ni nadie es lo que parece.', 'https://i.imgur.com/bjAWuTc.png', 'https://www.youtube-nocookie.com/embed/7mgu9mNZ8Hk?si=JwqMsRSDDgNEgewd');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('dune', 'Dune', 'Denis Villeneuve', 'Timothée Chalamet, Rebecca Ferguson, Oscar Isaac, Josh Brolin, Stellan Skarsgård, Dave Bautista, Stephen McKinley Henderson, Zendaya, Chang Chen, Sharon Duncan-Brewster, Charlotte Rampling, Jason Momoa, Javier Bardem', 155, 'Dune es una película de ciencia ficción épica estadounidense de 2021 dirigida y coproducida por Denis Villeneuve, quien coescribió el guion con Jon Spaihts y Eric Roth. Es la primera de una adaptación en dos partes de la novela de 1965 del mismo nombre de Frank Herbert.', 'https://i.imgur.com/TqqXEg4.png', 'https://www.youtube-nocookie.com/embed/n9xhJrPXop4?si=r4AsnaS5Kr3ER-0d');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('dune2', 'Dune: Part II', 'Denis Villeneuve', 'Timothée Chalamet, Rebecca Ferguson, Josh Brolin, Stellan Skarsgård, Dave Bautista, Zendaya, Charlotte Rampling, Javier Bardem, Austin Butler, Florence Pugh, Christopher Walken, Léa Seydoux, Souheila Yacoub', 165, 'Dune: Part Two es una película de ciencia ficción épica estadounidense de 2024 dirigida y coproducida por Denis Villeneuve, quien coescribió el guion con Jon Spaihts. La secuela de Dune (2021), es la segunda de una adaptación en dos partes de la novela de 1965 Dune de Frank Herbert.', 'https://i.imgur.com/oQ3Zltb.png', 'https://www.youtube-nocookie.com/embed/Way9Dexny3w?si=43_adQN2ZFaTawz6');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('kung_fu_panda_4', 'Kung Fu Panda 4', 'Mike Mitchell', 'Jack Black, Awkwafina, Bryan Cranston, James Hong, Ian McShane, Ke Huy Quan, Dustin Hoffman, Viola Davis', 94, 'Kung Fu Panda 4 es una película de comedia de artes marciales animada estadounidense de 2024 producida por DreamWorks Animation y distribuida por Universal Pictures. Es la cuarta entrega de la franquicia Kung Fu Panda y la secuela de Kung Fu Panda 3 (2016).', 'https://i.imgur.com/gYIVwq7.png', 'https://www.youtube-nocookie.com/embed/_inKs4eeHiI?si=jj8LRu3iGAFs9ixj');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('madame_web', 'Madame Web', 'S. J. Clarkson', 'Dakota Johnson, Sydney Sweeney, Isabela Merced, Celeste O´Connor, Tahar Rahim, Mike Epps, Emma Roberts, Adam Scott', 116, 'Madame Web es una película de superhéroes estadounidense de 2024 que presenta al personaje de cómics de Marvel del mismo nombre. Producida por Columbia Pictures y Di Bonaventura Pictures en asociación con Marvel Entertainment y TSG Entertainment, y distribuida por Sony Pictures Releasing, es la cuarta película en el Universo Spider-Man de Sony (SSU).', 'https://i.imgur.com/AXD5t8Z.png', 'https://www.youtube-nocookie.com/embed/s_76M4c4LTo?si=m6w7eGTxBH1i_yEm');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('one_love', 'One Love', 'Reinaldo Marcus Green', 'Kingsley Ben-Adir, Lashana Lynch, James Norton, Tosin Cole, Umi Myers, Anthony Welsh, Don Taylor, Nia Ashi, Teen Rita Marley, Quan-Dajai Henriques, Teen Bob Marley, Kait Tenison, Bene Gesserit Sister', 104, 'Bob Marley: One Love celebra la vida y la música de un ícono que inspiró a generaciones a través de su mensaje de amor y unidad. Por primera vez en la gran pantalla, descubre la poderosa historia de superación de Bob y el viaje detrás de su música revolucionaria.', 'https://i.imgur.com/vzPsQ5C.png', 'https://www.youtube-nocookie.com/embed/ajw425Kuvtw?si=Ordk2lArJ359PQpF');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('wicked', 'Wicked: Part I', 'Jon M. Chu', 'Cynthia Erivo, Ariana Grande, Michelle Yeoh, Jeff Goldblum, Jonathan Bailey, Ethan Slater, Marissa Bode, Bowen Yang, Bronwyn James, Keala Settle', 165, 'Una amistad improbable surge entre Elphaba y Glinda, dos brujas enfrentadas en la mágica tierra de Oz. Elphaba es injustamente catalogada como una bruja malvada mientras intenta exponer al farsante y corrupto Mago que gobierna la tierra.', 'https://i.imgur.com/rGkbqrw.jpg', 'https://www.youtube-nocookie.com/embed/F1dvX9Vs0ns?si=T2O1ceF16vLVLArM');")
sql.append("INSERT INTO Peliculas (idPelicula, Titulo, Directores, Actores, Duracion, Sinopsis, UrlCover, UrlTrailer) VALUES ('wonka', 'Wonka', 'Paul King', 'Timothée Chalamet, Calah Lane, Keegan-Michael Key, Paterson Joseph, Matt Lucas, Mathew Baynton, Sally Hawkins, Rowan Atkinson, Jim Carter, Olivia Colman, Hugh Grant', 116, 'Wonka es una película de fantasía musical de 2023 dirigida por Paul King, quien coescribió el guion con Simon Farnaby basado en una historia de King. Cuenta la historia de origen de Willy Wonka, un personaje de la novela de 1964 Charlie y la fábrica de chocolate de Roald Dahl, que representa sus primeros días como chocolatero.', 'https://i.imgur.com/YVrTNot.jpg', 'https://www.youtube-nocookie.com/embed/otNh9bTjXWg?si=m7QWpRY7we67Ftrp');")


sql.append("-- Menús")
sql.append("INSERT INTO Menus (idMenu, Descripcion, Precio) VALUES (secuencia_idMenu.NEXTVAL, 'Sin menú - Sin menú', 0);")
sql.append("INSERT INTO Menus (idMenu, Descripcion, Precio) VALUES (secuencia_idMenu.NEXTVAL, 'Menú infantil - Incluye un bol de palomitas pequeño y una botella de agua.', 4);")
sql.append("INSERT INTO Menus (idMenu, Descripcion, Precio) VALUES (secuencia_idMenu.NEXTVAL, 'Menú mediano - Incluye un bol de palomitas mediano y una bebida mediana a elegir.', 6);")
sql.append("INSERT INTO Menus (idMenu, Descripcion, Precio) VALUES (secuencia_idMenu.NEXTVAL, 'Menú grande - Incluye un bol de palomitas grande y una bebida grande a elegir.', 8);")
sql.append("INSERT INTO Menus (idMenu, Descripcion, Precio) VALUES (secuencia_idMenu.NEXTVAL, 'Better Together - Incluye un bol de palomitas extra grande, una bolsa de gominolas y 2 bebidas grandes a elegir.', 10);")


sql.append("-- Butacas")
for sala in range(1, salas + 1):
    sql += generar_butacas(nButacas, sala)


sql.append("-- Sesiones")
sql += generar_sesiones(sesiones_dia, hora_inicio, fecha_inicio, fecha_fin, salas, nButacas, peliculas)

with open("../sql/Oracle/script.sql", "w", encoding="utf-8") as f:
    for linea in sql:
        f.write(linea + "\n")