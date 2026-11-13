import uuid

from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.contrib.gis.db import models
from django.utils import timezone


class Parroquia(models.Model):
    nombre = models.CharField("nombre", max_length=100, unique=True)
    municipio = models.CharField("municipio", max_length=100, default="Vargas")
    centroide = models.PointField("centroide", srid=4326, null=True, blank=True)

    class Meta:
        ordering = ["nombre"]
        verbose_name = "parroquia"
        verbose_name_plural = "parroquias"

    def __str__(self):
        return self.nombre


class Rubro(models.Model):
    nombre = models.CharField("nombre", max_length=100, unique=True)

    class Meta:
        ordering = ["nombre"]
        verbose_name = "rubro"
        verbose_name_plural = "rubros"

    def __str__(self):
        return self.nombre


class Enfermedad(models.TextChoices):
    HONGOS = "hongos", "Hongos"
    BACTERIAS = "bacterias", "Bacterias"


class Plaga(models.TextChoices):
    INSECTOS = "insectos", "Insectos"
    ACAROS = "acaros", "Ácaros"
    NEMATODOS = "nematodos", "Nematodos"


class DestinoProduccion(models.TextChoices):
    CONSUMO_FAMILIAR = "consumo_familiar", "Consumo familiar"
    VENTA_LOCAL_COMUNAL = "venta_local_comunal", "Venta local / comunal"
    VENTA_MERCADOS_INDUSTRIAL = "venta_mercados_industrial", "Venta a mercados / industrial"


class TipoCultivo(models.TextChoices):
    MONOCULTIVO = "monocultivo", "Monocultivo"
    ROTATIVO = "rotativo", "Rotativo"
    ASOCIADO = "asociado", "Asociado"


class ProduccionAnimal(models.TextChoices):
    CAPRINO = "caprino", "Caprino"
    PORCINO = "porcino", "Porcino"
    AVICOLA = "avicola", "Avícola"
    OVINO = "ovino", "Ovino"
    ACUICULTURA = "acuicultura", "Acuicultura"
    BOVINO = "bovino", "Bovino"
    APICULTURA = "apicultura", "Apicultura"


OPCIONES_MULTIPLES = {
    "enfermedades": Enfermedad,
    "plagas": Plaga,
    "destino_produccion": DestinoProduccion,
    "tipos_cultivo": TipoCultivo,
    "produccion_animal": ProduccionAnimal,
}


def _multi(verbose_name, choices):
    return ArrayField(
        models.CharField(max_length=40, choices=choices.choices),
        verbose_name=verbose_name,
        default=list,
        blank=True,
    )


class ConsejoCampesino(models.Model):
    class TenenciaTierra(models.TextChoices):
        PROPIA = "propia", "Propia"
        ADJUDICADA_INTI = "adjudicada_inti", "Adjudicada por el INTI"
        ARRENDADA = "arrendada", "Arrendada"
        COMUNAL = "comunal", "Comunal"
        OCUPACION = "ocupacion", "Ocupación"
        OTRA = "otra", "Otra"

    class FuenteAgua(models.TextChoices):
        RIO_QUEBRADA = "rio_quebrada", "Río o quebrada"
        NACIENTE = "naciente", "Naciente"
        POZO = "pozo", "Pozo"
        ACUEDUCTO = "acueducto", "Acueducto"
        LLUVIA = "lluvia", "Lluvia"
        NINGUNA = "ninguna", "Ninguna"

    class Estado(models.TextChoices):
        ENVIADO = "enviado", "Enviado"
        VALIDADO = "validado", "Validado"
        RECHAZADO = "rechazado", "Rechazado"

    uuid = models.UUIDField("UUID del cliente", default=uuid.uuid4, unique=True, editable=False)
    nombre = models.CharField("nombre", max_length=200)
    rif = models.CharField("RIF", max_length=30, blank=True)
    codigo_registro = models.CharField("código de registro", max_length=80, blank=True)
    parroquia = models.ForeignKey(
        Parroquia,
        verbose_name="parroquia",
        on_delete=models.PROTECT,
        related_name="consejos",
    )
    sector = models.CharField("sector", max_length=150, blank=True)
    direccion = models.TextField("dirección", blank=True)
    ubicacion = models.PointField("ubicación", srid=4326)
    precision_gps_m = models.FloatField("precisión GPS (m)", null=True, blank=True)
    altitud_m = models.FloatField("altitud (m)", null=True, blank=True)
    fecha_constitucion = models.DateField("fecha de constitución", null=True, blank=True)
    num_familias = models.PositiveIntegerField("número de familias", default=0)
    num_hombres = models.PositiveIntegerField("número de hombres", default=0)
    num_mujeres = models.PositiveIntegerField("número de mujeres", default=0)
    num_jovenes = models.PositiveIntegerField("número de jóvenes", default=0)
    superficie_ha = models.DecimalField(
        "superficie (ha)", max_digits=10, decimal_places=2, null=True, blank=True
    )
    tenencia_tierra = models.CharField(
        "tenencia de la tierra",
        max_length=30,
        choices=TenenciaTierra.choices,
        blank=True,
    )
    fuente_agua = models.CharField(
        "fuente de agua", max_length=30, choices=FuenteAgua.choices, blank=True
    )
    tiene_riego = models.BooleanField("tiene riego", default=False)
    rubros = models.ManyToManyField(Rubro, verbose_name="rubros", related_name="consejos", blank=True)
    enfermedades = _multi("enfermedades en la cosecha", Enfermedad)
    plagas = _multi("plagas", Plaga)
    destino_produccion = _multi("destino de la producción", DestinoProduccion)
    tipos_cultivo = _multi("tipos de cultivo", TipoCultivo)
    produccion_animal = _multi("producción animal", ProduccionAnimal)
    requerimientos = models.TextField("requerimientos y otros", blank=True)
    necesidades = models.TextField("necesidades", blank=True)
    observaciones = models.TextField("observaciones", blank=True)
    estado = models.CharField(
        "estado", max_length=20, choices=Estado.choices, default=Estado.ENVIADO
    )
    registrado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        verbose_name="registrado por",
        on_delete=models.PROTECT,
        related_name="consejos_registrados",
    )
    dispositivo_id = models.CharField("identificador del dispositivo", max_length=150, blank=True)
    fecha_captura = models.DateTimeField("fecha de captura", default=timezone.now)
    creado = models.DateTimeField("creado", auto_now_add=True)
    actualizado = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        ordering = ["-fecha_captura", "-id"]
        verbose_name = "consejo campesino"
        verbose_name_plural = "consejos campesinos"

    def __str__(self):
        return self.nombre


class Vocero(models.Model):
    consejo = models.ForeignKey(
        ConsejoCampesino, verbose_name="consejo campesino", on_delete=models.CASCADE, related_name="voceros"
    )
    nombre = models.CharField("nombre", max_length=160)
    cedula = models.CharField("cédula", max_length=30, blank=True)
    telefono = models.CharField("teléfono", max_length=30, blank=True)
    cargo = models.CharField("cargo", max_length=100, blank=True)
    es_principal = models.BooleanField("es principal", default=False)

    class Meta:
        verbose_name = "vocero"
        verbose_name_plural = "voceros"

    def __str__(self):
        return self.nombre


class Foto(models.Model):
    consejo = models.ForeignKey(
        ConsejoCampesino, verbose_name="consejo campesino", on_delete=models.CASCADE, related_name="fotos"
    )
    imagen = models.ImageField("imagen", upload_to="consejos/%Y/%m/")
    descripcion = models.CharField("descripción", max_length=255, blank=True)
    uuid = models.UUIDField("UUID del cliente", default=uuid.uuid4, unique=True)
    creado = models.DateTimeField("creado", auto_now_add=True)

    class Meta:
        ordering = ["id"]
        verbose_name = "fotografía"
        verbose_name_plural = "fotografías"

    def __str__(self):
        return self.descripcion or str(self.uuid)
