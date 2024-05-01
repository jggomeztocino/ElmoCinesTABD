import random
from datetime import datetime, timedelta
import names  # https://pypi.org/project/names/

def generar_butacas(nButacas, sala):
     """
     Genera butacas.
     """

     sql = []

     for _ in range(1, nButacas + 1):
         sql.append(f"INSERT INTO Butacas (idButaca, NumeroSala) VALUES (secuencia_idButaca.NEXTVAL, {sala});")

     return sql

def generar_cliente(sql):
    nombre = names.get_full_name();
    email = f"{nombre.replace(' ', '.').lower()}@guest.elmocines.com"
    telefono = f"6{random.randint(600000000, 699999999)}"
    cliente = {"Nombre": nombre, "Email": email, "Telefono": telefono}
    sql.append(f"INSERT INTO Clientes (Correo, Nombre, Telefono) VALUES ('{email}', '{nombre}', '{telefono}');")
    sql.append(f"COMMIT;")
    return cliente, sql

def generar_entrada():
    idEntrada = f"secuencia_idEntrada.NEXTVAL"
    idMenu = random.choice([1,2,3,4,5])
    idMenu = f"(SELECT REF(m) FROM Menus m WHERE m.idMenu = {idMenu})"
    Descripcion = random.choice(["Entrada adulta", "Entrada infantil"])
    Precio = 6 if Descripcion == "Entrada adulta" else 4
    entrada = {"idEntrada": idEntrada, "idMenu": idMenu, "Descripcion": Descripcion, "Precio": Precio}
    #sql.append(f"INSERT INTO Entradas (idEntrada, idMenu, Descripcion, Precio) VALUES ({idEntrada}, {idMenu}, '{Descripcion}', {Precio});")
    #sql.append(f"COMMIT;")
    return entrada

def generar_reservaButaca(sql, idButaca, NumeroSala):
    idButacaReserva = f"secuencia_idButacaReserva.NEXTVAL"
    butaca = f"(SELECT REF(b) FROM Butacas b WHERE b.idButaca = {idButaca} AND b.NumeroSala = {NumeroSala})"
    sql.append(f"DECLARE reserva NUMBER; BEGIN SELECT SECUENCIA_IDRESERVA.CURRVAL INTO reserva FROM DUAL;")
    idReserva = f"(SELECT REF(r) FROM Reservas r WHERE idReserva = reserva)"
    sql.append(f"INSERT INTO ButacasReservas (idButacaReserva, refButaca, refReserva) VALUES ({idButacaReserva}, {butaca}, {idReserva});")
    sql.append(f"COMMIT; END; /")
    return sql

def generar_reserva(sql, butaca, NumeroSala):
    """
        Genera una reserva, junto a su cliente y entrada
    """
    cliente, sql = generar_cliente(sql)
    sql.append(f"DECLARE sesion NUMBER; BEGIN SELECT SECUENCIA_IDSESION.CURRVAL INTO sesion FROM DUAL;")
    idReserva = f"secuencia_idReserva.NEXTVAL" 
    idSesion = f"(SELECT REF(s) FROM Sesiones s WHERE idSesion = sesion)" 
    idCliente = cliente["Email"]
    idCliente = f"(SELECT REF(c) FROM Clientes c WHERE c.Correo = '{idCliente}')"
    FormaPago = random.choice(["Efectivo", "Tarjeta"])
    FechaCompra = f"TO_TIMESTAMP('{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}', 'YYYY-MM-DD HH24:MI:SS')"
    entrada = generar_entrada()
    sql.append(f"INSERT INTO Reservas (idReserva, idSesion, idCliente, FormaPago, FechaCompra, Entradas) VALUES ({idReserva}, {idSesion}, {idCliente}, '{FormaPago}', {FechaCompra}, TipoEntradaArray(TipoEntrada({entrada["idEntrada"]}, {entrada["idMenu"]}, '{entrada["Descripcion"]}', {entrada["Precio"]})));")
    sql.append(f"COMMIT; END; /")
    sql = generar_reservaButaca(sql, butaca, NumeroSala)
    #sql = generar_entrada(sql)
    return sql

def generar_sesiones(sesiones_dia, hora_inicio, fecha_inicio, fecha_fin, salas, nButacas, peliculas):
    """
    Genera sesiones de cine.
    """

    sql = []

    minutos = [0, 15, 30, 45]

    for pelicula in peliculas:
        fecha_actual = fecha_inicio
        while(fecha_actual < fecha_fin):
            if random.random() <= 0.5:
                hora_actual = hora_inicio
                for _ in range(1, sesiones_dia + 1):
                    idSesion = f"secuencia_idSesion.NEXTVAL"
                    idPelicula = f"(SELECT REF(p) FROM Peliculas p WHERE p.idPelicula = '{pelicula}')"
                    NumeroSala = random.randint(1, salas)
                    FechaHora = f"TO_TIMESTAMP('{fecha_actual.strftime('%Y-%m-%d')} {hora_actual}:{minutos[random.randint(0, 3)]}:00', 'YYYY-MM-DD HH24:MI:SS')"
                    sql.append(f"INSERT INTO Sesiones (idSesion, idPelicula, NumeroSala, FechaHora) VALUES ({idSesion}, {idPelicula}, {NumeroSala}, {FechaHora});")
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
fecha_inicio = datetime(2024, 5, 1)
fecha_fin = datetime(2024, 5, 15)
salas = 8
nButacas = 30
sesiones_dia = 5
hora_inicio = 15  # Hora de inicio base de las sesiones (15:00)
probabilidad_ocupado = 0.1

peliculas = ['wicked', 'argylle', 'dune', 'dune2', 'one_love', 'wonka', 'madame_web', 'kung_fu_panda_4']

# Generación de butacas en butacas.sql para todas las salas
sql = []
for sala in range(1, salas + 1):
    sql += generar_butacas(nButacas, sala)
with open("butacas.sql", "w") as f:
    for linea in sql:
        f.write(linea + "\n")

# Generación de sesiones en sesiones.sql
sql = []
sql = generar_sesiones(sesiones_dia, hora_inicio, fecha_inicio, fecha_fin, salas, nButacas, peliculas)
with open("sesiones.sql", "w") as f:
    for linea in sql:
        f.write(linea + "\n")