import random
from datetime import datetime, timedelta
import json
import names  # https://pypi.org/project/names/


def generar_butacas(max_butacas):
    """
    Genera una lista de butacas con estados aleatorios entre 'libre' y 'ocupado'.
    Las butacas ocupadas incluirán un email generado aleatoriamente.
    """
    filas = ['A', 'B', 'C', 'D', 'E', 'F']
    columnas = [1, 2, 3, 4, 5]
    butacas = []
    for fila in filas:
        for columna in columnas:
            butaca = {"numero": f"{fila}{columna}", "estado": "libre"}
            butacas.append(butaca)

    butacas_ocupadas = random.sample(butacas, max_butacas)
    for butaca in butacas_ocupadas:
        butaca["estado"] = "ocupado"
        nombre_completo = names.get_full_name().lower().replace(' ',
                                                                '_')  # Genera un nombre completo, lo convierte a minúsculas y reemplaza espacios por guiones bajos
        butaca["email"] = f"{nombre_completo}@guests.elmocines.com"

    return sorted(butacas, key=lambda x: x["numero"])


def generar_sesiones(fecha_inicio, fecha_fin, max_sala, total_butacas, sesiones_por_dia, hora_inicio=15,
                     probabilidad_dia_vacio=0.1):
    """
    Genera sesiones aleatorias entre las fechas de inicio y fin, con detalles como
    la hora de inicio, sala, y butacas disponibles/ocupadas.
    """
    sesiones = []
    fecha_actual = fecha_inicio

    while fecha_actual <= fecha_fin:
        if random.random() > probabilidad_dia_vacio:  # Probabilidad de generar sesiones en un día determinado
            horario_sesion = hora_inicio
            for _ in range(sesiones_por_dia):
                if horario_sesion >= 24:
                    break
                minuto = random.randint(0, 59)
                hora = f"{horario_sesion:02d}:{minuto:02d}"
                sala = random.randint(1, max_sala)
                butacas_libres = random.randint(0, total_butacas)
                id_sesion = f"{fecha_actual.strftime('%Y%m%d')}-{hora.replace(':', '')}"  # ID único de la sesión
                sesion = {
                    "_id": id_sesion,
                    "fecha": fecha_actual.strftime("%Y-%m-%d"),
                    "hora": hora,
                    "sala": sala,
                    "butacas_libres": butacas_libres,
                    "butacas_detalles": generar_butacas(total_butacas - butacas_libres)
                }
                sesiones.append(sesion)
                horario_sesion += random.randint(1, (24 - hora_inicio) // sesiones_por_dia)

        fecha_actual += timedelta(days=1)

    return sesiones


# Datos para la generación de sesiones
id_peliculas = ['wicked', 'argylle', 'wonka', 'dune', 'dune2', 'kung_fu_panda_4', 'one_love', 'madame_web']
fecha_inicio = datetime(2024, 4, 1)
fecha_fin = datetime(2024, 4, 30)
max_sala = 15
total_butacas = 30  # Total de butacas por sesión
sesiones_por_dia = 5
hora_inicio_sesiones = 15  # Hora de inicio de las sesiones (15:00)
probabilidad_dia_vacio = 0.1  # Probabilidad de que un día no tenga sesiones

print("Generando sesiones...")
for id_pelicula in id_peliculas:
    # Generar y guardar sesiones
    sesiones = generar_sesiones(fecha_inicio, fecha_fin, max_sala, total_butacas, sesiones_por_dia,
                                hora_inicio_sesiones, probabilidad_dia_vacio)
    nombre_archivo = f"{id_pelicula}-sesiones.json"
    with open(nombre_archivo, 'w') as archivo:
        json.dump(sesiones, archivo, indent=2, ensure_ascii=False)

    print(f"El archivo '{nombre_archivo}' ha sido generado con éxito.")
