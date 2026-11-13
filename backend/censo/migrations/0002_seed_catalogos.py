from django.contrib.gis.geos import Point
from django.db import migrations


PARROQUIAS = [
    ("Caraballeda", 10.610, -66.850),
    ("Carayaca", 10.530, -67.120),
    ("Carlos Soublette", 10.590, -66.990),
    ("Caruao", 10.610, -66.370),
    ("Catia La Mar", 10.600, -67.030),
    ("El Junko", 10.490, -67.080),
    ("La Guaira", 10.600, -66.930),
    ("Macuto", 10.605, -66.890),
    ("Maiquetía", 10.595, -66.960),
    ("Naiguatá", 10.620, -66.740),
    ("Urimare", 10.598, -67.050),
]

RUBROS = [
    "Café",
    "Cacao",
    "Hortalizas",
    "Frutales",
    "Cambur/Plátano",
    "Aguacate",
    "Raíces y tubérculos",
    "Granos",
    "Flores",
    "Ganadería bovina",
    "Ganadería caprina/ovina",
    "Avicultura",
    "Porcinos",
    "Apicultura",
    "Pesca artesanal",
    "Otro",
]


def seed_catalogos(apps, schema_editor):
    Parroquia = apps.get_model("censo", "Parroquia")
    Rubro = apps.get_model("censo", "Rubro")
    Group = apps.get_model("auth", "Group")
    for nombre, lat, lng in PARROQUIAS:
        Parroquia.objects.update_or_create(
            nombre=nombre,
            defaults={"municipio": "Vargas", "centroide": Point(lng, lat, srid=4326)},
        )
    for nombre in RUBROS:
        Rubro.objects.get_or_create(nombre=nombre)
    for nombre in ("administrador", "supervisor", "encuestador"):
        Group.objects.get_or_create(name=nombre)


def unseed_catalogos(apps, schema_editor):
    Parroquia = apps.get_model("censo", "Parroquia")
    Rubro = apps.get_model("censo", "Rubro")
    Group = apps.get_model("auth", "Group")
    Parroquia.objects.filter(nombre__in=[row[0] for row in PARROQUIAS]).delete()
    Rubro.objects.filter(nombre__in=RUBROS).delete()
    Group.objects.filter(name__in=("administrador", "supervisor", "encuestador")).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("auth", "0012_alter_user_first_name_max_length"),
        ("censo", "0001_initial"),
    ]

    operations = [migrations.RunPython(seed_catalogos, unseed_catalogos)]
