import uuid

import django.contrib.gis.db.models.fields
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="Parroquia",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("nombre", models.CharField(max_length=100, unique=True, verbose_name="nombre")),
                ("municipio", models.CharField(default="Vargas", max_length=100, verbose_name="municipio")),
                (
                    "centroide",
                    django.contrib.gis.db.models.fields.PointField(
                        blank=True, null=True, srid=4326, verbose_name="centroide"
                    ),
                ),
            ],
            options={
                "verbose_name": "parroquia",
                "verbose_name_plural": "parroquias",
                "ordering": ["nombre"],
            },
        ),
        migrations.CreateModel(
            name="Rubro",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("nombre", models.CharField(max_length=100, unique=True, verbose_name="nombre")),
            ],
            options={"verbose_name": "rubro", "verbose_name_plural": "rubros", "ordering": ["nombre"]},
        ),
        migrations.CreateModel(
            name="ConsejoCampesino",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                (
                    "uuid",
                    models.UUIDField(
                        default=uuid.uuid4, editable=False, unique=True, verbose_name="UUID del cliente"
                    ),
                ),
                ("nombre", models.CharField(max_length=200, verbose_name="nombre")),
                ("rif", models.CharField(blank=True, max_length=30, verbose_name="RIF")),
                ("codigo_registro", models.CharField(blank=True, max_length=80, verbose_name="código de registro")),
                ("sector", models.CharField(blank=True, max_length=150, verbose_name="sector")),
                ("direccion", models.TextField(blank=True, verbose_name="dirección")),
                (
                    "ubicacion",
                    django.contrib.gis.db.models.fields.PointField(srid=4326, verbose_name="ubicación"),
                ),
                ("precision_gps_m", models.FloatField(blank=True, null=True, verbose_name="precisión GPS (m)")),
                ("altitud_m", models.FloatField(blank=True, null=True, verbose_name="altitud (m)")),
                ("fecha_constitucion", models.DateField(blank=True, null=True, verbose_name="fecha de constitución")),
                ("num_familias", models.PositiveIntegerField(default=0, verbose_name="número de familias")),
                ("num_hombres", models.PositiveIntegerField(default=0, verbose_name="número de hombres")),
                ("num_mujeres", models.PositiveIntegerField(default=0, verbose_name="número de mujeres")),
                ("num_jovenes", models.PositiveIntegerField(default=0, verbose_name="número de jóvenes")),
                (
                    "superficie_ha",
                    models.DecimalField(
                        blank=True, decimal_places=2, max_digits=10, null=True, verbose_name="superficie (ha)"
                    ),
                ),
                (
                    "tenencia_tierra",
                    models.CharField(
                        blank=True,
                        choices=[
                            ("propia", "Propia"),
                            ("adjudicada_inti", "Adjudicada por el INTI"),
                            ("arrendada", "Arrendada"),
                            ("comunal", "Comunal"),
                            ("ocupacion", "Ocupación"),
                            ("otra", "Otra"),
                        ],
                        max_length=30,
                        verbose_name="tenencia de la tierra",
                    ),
                ),
                (
                    "fuente_agua",
                    models.CharField(
                        blank=True,
                        choices=[
                            ("rio_quebrada", "Río o quebrada"),
                            ("naciente", "Naciente"),
                            ("pozo", "Pozo"),
                            ("acueducto", "Acueducto"),
                            ("lluvia", "Lluvia"),
                            ("ninguna", "Ninguna"),
                        ],
                        max_length=30,
                        verbose_name="fuente de agua",
                    ),
                ),
                ("tiene_riego", models.BooleanField(default=False, verbose_name="tiene riego")),
                ("necesidades", models.TextField(blank=True, verbose_name="necesidades")),
                ("observaciones", models.TextField(blank=True, verbose_name="observaciones")),
                (
                    "estado",
                    models.CharField(
                        choices=[
                            ("enviado", "Enviado"),
                            ("validado", "Validado"),
                            ("rechazado", "Rechazado"),
                        ],
                        default="enviado",
                        max_length=20,
                        verbose_name="estado",
                    ),
                ),
                ("dispositivo_id", models.CharField(blank=True, max_length=150, verbose_name="identificador del dispositivo")),
                ("fecha_captura", models.DateTimeField(default=django.utils.timezone.now, verbose_name="fecha de captura")),
                ("creado", models.DateTimeField(auto_now_add=True, verbose_name="creado")),
                ("actualizado", models.DateTimeField(auto_now=True, verbose_name="actualizado")),
                (
                    "parroquia",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="consejos",
                        to="censo.parroquia",
                        verbose_name="parroquia",
                    ),
                ),
                (
                    "registrado_por",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="consejos_registrados",
                        to=settings.AUTH_USER_MODEL,
                        verbose_name="registrado por",
                    ),
                ),
                (
                    "rubros",
                    models.ManyToManyField(blank=True, related_name="consejos", to="censo.rubro", verbose_name="rubros"),
                ),
            ],
            options={
                "verbose_name": "consejo campesino",
                "verbose_name_plural": "consejos campesinos",
                "ordering": ["-fecha_captura", "-id"],
            },
        ),
        migrations.CreateModel(
            name="Foto",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("imagen", models.ImageField(upload_to="consejos/%Y/%m/", verbose_name="imagen")),
                ("descripcion", models.CharField(blank=True, max_length=255, verbose_name="descripción")),
                ("uuid", models.UUIDField(default=uuid.uuid4, unique=True, verbose_name="UUID del cliente")),
                ("creado", models.DateTimeField(auto_now_add=True, verbose_name="creado")),
                (
                    "consejo",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="fotos",
                        to="censo.consejocampesino",
                        verbose_name="consejo campesino",
                    ),
                ),
            ],
            options={"verbose_name": "fotografía", "verbose_name_plural": "fotografías", "ordering": ["id"]},
        ),
        migrations.CreateModel(
            name="Vocero",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("nombre", models.CharField(max_length=160, verbose_name="nombre")),
                ("cedula", models.CharField(blank=True, max_length=30, verbose_name="cédula")),
                ("telefono", models.CharField(blank=True, max_length=30, verbose_name="teléfono")),
                ("cargo", models.CharField(blank=True, max_length=100, verbose_name="cargo")),
                ("es_principal", models.BooleanField(default=False, verbose_name="es principal")),
                (
                    "consejo",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="voceros",
                        to="censo.consejocampesino",
                        verbose_name="consejo campesino",
                    ),
                ),
            ],
            options={"verbose_name": "vocero", "verbose_name_plural": "voceros"},
        ),
    ]
