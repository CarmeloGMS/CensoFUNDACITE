import random
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.contrib.gis.geos import Point
from django.core.management.base import BaseCommand
from django.utils import timezone

from censo.models import OPCIONES_MULTIPLES, ConsejoCampesino, Parroquia, Rubro, Vocero

User = get_user_model()

DEMO_USERS = [
    ("admin", "admin123", "administrador", True),
    ("supervisor", "supervisor123", "supervisor", False),
    ("encuestador1", "encuestador123", "encuestador", False),
    ("encuestador2", "encuestador123", "encuestador", False),
]

NOMBRES = [
    "Cacao de Chuao",
    "Sembradores de Carayaca",
    "La Esperanza de Naiguatá",
    "Café de El Junko",
    "Productores de Caruao",
    "Las Brisas de Macuto",
    "Unión Agrícola de Urimare",
    "El Renacer de Maiquetía",
    "Frutos de Galipán",
    "Manos de La Guaira",
    "Raíces de Todasana",
    "Valles de Caraballeda",
    "Cosecha de Tarmas",
    "La Ceiba de Osma",
    "Productores del Limón",
    "Agroecológico de Chichiriviche",
    "Semillas de Oritapo",
    "Café y Montaña de Carayaca",
    "El Paraíso de Caruao",
    "Cacao Criollo de Chuspa",
    "La Ceiba de Naiguatá",
    "Agricultores de El Cojo",
    "Productores de Todasana",
    "El Manglar de Urimare",
    "Hortalizas de La Peñita",
    "Campesinos de Las Salinas",
    "Frutales de Caruao",
    "La Montaña de El Junko",
    "Manos Unidas de Carayaca",
    "Cosecheros de Anare",
    "El Guamo de Naiguatá",
    "Los Pinos de Galipán",
    "Sembrando Futuro en Tarmas",
    "Café de San José de Galipán",
    "Agroproductores de La Sabana",
    "Frutos del Ávila",
    "La Alegría de Chuspa",
    "Cacao y Miel de Caruao",
    "Productores Unidos de Catia La Mar",
    "Hortalizas de El Junko",
    "El Progreso de Urimare",
    "Raíces de Todasana",
    "La Fortaleza de Carayaca",
    "Agricultores de Osma",
    "Semillas de Macuto",
]

SECTORES = [
    "La Peñita",
    "El Topo",
    "San José",
    "Las Flores",
    "Quebrada Seca",
    "El Potrero",
    "La Cumbre",
    "El Limón",
    "La Esperanza",
    "Los Claveles",
    "La Sabana",
]
VOCEROS = [
    "María González",
    "José Rodríguez",
    "Carmen Pérez",
    "Luis Hernández",
    "Ana Martínez",
    "Pedro García",
    "Rosa Sánchez",
    "Miguel Díaz",
    "Yolanda Rojas",
    "Carlos Flores",
    "Elena Castillo",
    "Francisco López",
]
TELEFONOS = ("0414", "0424", "0412")


def _muestra(rng, opciones, minimo=0):
    valores = [value for value, _ in opciones.choices]
    return rng.sample(valores, rng.randint(minimo, min(3, len(valores))))


class Command(BaseCommand):
    help = "Crea usuarios y aproximadamente 45 registros de demostración."

    def add_arguments(self, parser):
        parser.add_argument("--reset", action="store_true", help="Borra solo los registros de demostración y los recrea.")

    def handle(self, *args, **options):
        rng = random.Random(2025)
        if options["reset"]:
            ConsejoCampesino.objects.filter(dispositivo_id="seed_demo").delete()

        for username, password, role, is_admin in DEMO_USERS:
            user, created = User.objects.get_or_create(
                username=username,
                defaults={
                    "first_name": {
                        "admin": "Administración",
                        "supervisor": "María",
                        "encuestador1": "José",
                        "encuestador2": "Carmen",
                    }[username],
                    "last_name": "Censo",
                    "email": f"{username}@censo.local",
                },
            )
            if created:
                user.set_password(password)
            user.is_staff = is_admin
            user.is_superuser = is_admin
            user.save()
            user.groups.set([Group.objects.get(name=role)])

        if ConsejoCampesino.objects.filter(dispositivo_id="seed_demo").exists():
            self.stdout.write(self.style.SUCCESS("Los registros de demostración ya existen; no se duplicaron."))
            return

        parroquias = list(Parroquia.objects.order_by("id"))
        rubros = list(Rubro.objects.order_by("id"))
        encuestadores = [User.objects.get(username="encuestador1"), User.objects.get(username="encuestador2")]
        now = timezone.now()
        for index, nombre in enumerate(NOMBRES):
            parroquia = parroquias[index % len(parroquias)]
            centroide = parroquia.centroide
            council = ConsejoCampesino.objects.create(
                nombre=f"Consejo Campesino {nombre}",
                rif=f"J-{rng.randint(10000000, 99999999)}-{rng.randint(0, 9)}",
                codigo_registro=f"LG-{2024 + index % 2}-{index + 1:03d}",
                parroquia=parroquia,
                sector=rng.choice(SECTORES),
                direccion=f"Vía agrícola, sector {rng.choice(SECTORES)}, estado La Guaira",
                ubicacion=Point(
                    centroide.x + rng.uniform(-0.03, 0.03),
                    centroide.y + rng.uniform(-0.045, -0.005),
                    srid=4326,
                ),
                precision_gps_m=round(rng.uniform(2, 18), 1),
                altitud_m=round(rng.uniform(80, 1150), 1),
                fecha_constitucion=(now - timedelta(days=rng.randint(365, 5000))).date(),
                num_familias=rng.randint(12, 95),
                num_hombres=rng.randint(15, 90),
                num_mujeres=rng.randint(18, 100),
                num_jovenes=rng.randint(5, 45),
                superficie_ha=round(rng.uniform(4, 180), 2),
                tenencia_tierra=rng.choice([choice[0] for choice in ConsejoCampesino.TenenciaTierra.choices]),
                fuente_agua=rng.choice([choice[0] for choice in ConsejoCampesino.FuenteAgua.choices]),
                tiene_riego=rng.choice([True, False]),
                **{
                    campo: _muestra(rng, opciones, minimo=1 if campo in {"destino_produccion", "tipos_cultivo"} else 0)
                    for campo, opciones in OPCIONES_MULTIPLES.items()
                },
                requerimientos=rng.choice(["", "Insumos para control biológico de plagas.", "Capacitación en manejo poscosecha.", "Transporte para llevar la cosecha al mercado."]),
                necesidades=rng.choice(
                    [
                        "Mejorar el acceso al agua para riego.",
                        "Apoyo para herramientas y semillas.",
                        "Rehabilitación del camino de acceso.",
                        "Asistencia técnica para producción agroecológica.",
                    ]
                ),
                observaciones="Registro de demostración con datos ficticios.",
                estado=(
                    ConsejoCampesino.Estado.VALIDADO
                    if index < 27
                    else ConsejoCampesino.Estado.ENVIADO
                    if index < 41
                    else ConsejoCampesino.Estado.RECHAZADO
                ),
                registrado_por=encuestadores[index % len(encuestadores)],
                dispositivo_id="seed_demo",
                fecha_captura=now - timedelta(days=rng.randint(0, 243), hours=rng.randint(0, 23)),
            )
            council.rubros.set(rng.sample(rubros, rng.randint(1, 4)))
            for vocero_index in range(rng.randint(1, 3)):
                cedula = f"V-{rng.randint(10, 32)}.{rng.randint(100, 999)}.{rng.randint(100, 999)}"
                telefono = rng.choice(TELEFONOS) + f"-{rng.randint(100, 999)}-{rng.randint(1000, 9999)}"
                Vocero.objects.create(
                    consejo=council,
                    nombre=rng.choice(VOCEROS),
                    cedula=cedula,
                    telefono=telefono,
                    cargo="Vocería de producción" if vocero_index == 0 else "Vocería de organización",
                    es_principal=vocero_index == 0,
                )

        self.stdout.write(self.style.SUCCESS(f"Se crearon {len(NOMBRES)} consejos de demostración."))
