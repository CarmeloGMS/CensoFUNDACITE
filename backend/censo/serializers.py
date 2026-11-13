from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.contrib.gis.geos import Point
from rest_framework import serializers

from .models import ConsejoCampesino, Foto, Parroquia, Rubro, Vocero

User = get_user_model()
ROLES = ("administrador", "supervisor", "encuestador")


class RoleField(serializers.Field):
    def get_attribute(self, instance):
        return instance

    def to_representation(self, user):
        return user.groups.order_by("name").values_list("name", flat=True).first()

    def to_internal_value(self, data):
        return data


class VoceroSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vocero
        fields = ("id", "nombre", "cedula", "telefono", "cargo", "es_principal")
        read_only_fields = ("id",)


class ConsejoSerializer(serializers.ModelSerializer):
    parroquia = serializers.SerializerMethodField()
    parroquia_id = serializers.PrimaryKeyRelatedField(
        source="parroquia", queryset=Parroquia.objects.all(), write_only=True
    )
    rubros = serializers.SerializerMethodField()
    rubro_ids = serializers.PrimaryKeyRelatedField(
        source="rubros", queryset=Rubro.objects.all(), many=True, required=False, write_only=True
    )
    lat = serializers.SerializerMethodField()
    lng = serializers.SerializerMethodField()
    registrado_por = serializers.SerializerMethodField()
    voceros = VoceroSerializer(many=True, required=False)
    fotos = serializers.SerializerMethodField()
    uuid = serializers.UUIDField(required=False)

    class Meta:
        model = ConsejoCampesino
        fields = (
            "id",
            "uuid",
            "nombre",
            "rif",
            "codigo_registro",
            "parroquia",
            "parroquia_id",
            "sector",
            "direccion",
            "lat",
            "lng",
            "precision_gps_m",
            "altitud_m",
            "fecha_constitucion",
            "num_familias",
            "num_hombres",
            "num_mujeres",
            "num_jovenes",
            "superficie_ha",
            "tenencia_tierra",
            "fuente_agua",
            "tiene_riego",
            "rubros",
            "rubro_ids",
            "necesidades",
            "observaciones",
            "estado",
            "registrado_por",
            "dispositivo_id",
            "fecha_captura",
            "creado",
            "actualizado",
            "voceros",
            "fotos",
        )
        read_only_fields = ("id", "estado", "registrado_por", "creado", "actualizado", "fotos")

    def validate_uuid(self, value):
        if self.instance is not None and value != self.instance.uuid:
            raise serializers.ValidationError("El UUID de un registro existente no se puede cambiar.")
        return value

    def to_internal_value(self, data):
        values = data.copy()
        lat = values.pop("lat", None)
        lng = values.pop("lng", None)
        if (lat is None) != (lng is None):
            raise serializers.ValidationError({"lat": "Debe enviar lat y lng juntos."})
        if lat is not None:
            try:
                lat, lng = float(lat), float(lng)
            except (TypeError, ValueError):
                raise serializers.ValidationError({"lat": "Las coordenadas deben ser numéricas."})
            if not -90 <= lat <= 90 or not -180 <= lng <= 180:
                raise serializers.ValidationError({"lat": "Las coordenadas están fuera de rango."})
        elif self.instance is None:
            raise serializers.ValidationError({"lat": "lat y lng son requeridos."})

        result = super().to_internal_value(values)
        if lat is not None:
            result["ubicacion"] = Point(lng, lat, srid=4326)
        return result

    def get_parroquia(self, obj):
        return {"id": obj.parroquia_id, "nombre": obj.parroquia.nombre}

    def get_rubros(self, obj):
        return [{"id": rubro.id, "nombre": rubro.nombre} for rubro in obj.rubros.all()]

    def get_lat(self, obj):
        return obj.ubicacion.y

    def get_lng(self, obj):
        return obj.ubicacion.x

    def get_registrado_por(self, obj):
        user = obj.registrado_por
        nombre = " ".join(part for part in (user.first_name, user.last_name) if part).strip()
        return {"id": user.id, "username": user.username, "nombre": nombre}

    def get_fotos(self, obj):
        request = self.context.get("request")
        fotos = []
        for foto in obj.fotos.all():
            url = foto.imagen.url if foto.imagen else ""
            if request and url:
                url = request.build_absolute_uri(url)
            fotos.append(
                {"id": foto.id, "uuid": foto.uuid, "url": url, "descripcion": foto.descripcion}
            )
        return fotos

    def create(self, validated_data):
        voceros = validated_data.pop("voceros", [])
        rubros = validated_data.pop("rubros", [])
        consejo = ConsejoCampesino.objects.create(**validated_data)
        consejo.rubros.set(rubros)
        for vocero in voceros:
            Vocero.objects.create(consejo=consejo, **vocero)
        return consejo

    def update(self, instance, validated_data):
        voceros = validated_data.pop("voceros", None)
        rubros = validated_data.pop("rubros", None)
        for field, value in validated_data.items():
            setattr(instance, field, value)
        instance.save()
        if rubros is not None:
            instance.rubros.set(rubros)
        if voceros is not None:
            instance.voceros.all().delete()
            for vocero in voceros:
                Vocero.objects.create(consejo=instance, **vocero)
        return instance


class FotoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()
    imagen = serializers.ImageField(write_only=True)

    class Meta:
        model = Foto
        fields = ("id", "uuid", "url", "descripcion", "imagen")
        read_only_fields = ("id", "url")

    def get_url(self, obj):
        request = self.context.get("request")
        url = obj.imagen.url if obj.imagen else ""
        return request.build_absolute_uri(url) if request and url else url


class UsuarioSerializer(serializers.ModelSerializer):
    rol = RoleField()
    password = serializers.CharField(write_only=True, required=False, min_length=8)

    class Meta:
        model = User
        fields = (
            "id",
            "username",
            "first_name",
            "last_name",
            "email",
            "rol",
            "is_active",
            "password",
        )
        extra_kwargs = {"is_active": {"required": False}}

    def validate_rol(self, value):
        if value not in ROLES:
            raise serializers.ValidationError(f"El rol debe ser uno de: {', '.join(ROLES)}.")
        return value

    def validate(self, attrs):
        if self.instance is None and not attrs.get("password"):
            raise serializers.ValidationError({"password": "Este campo es requerido."})
        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        role = validated_data.pop("rol")
        user = User.objects.create_user(password=password, **validated_data)
        user.groups.set([Group.objects.get(name=role)])
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        role = validated_data.pop("rol", None)
        for field, value in validated_data.items():
            setattr(instance, field, value)
        if password:
            instance.set_password(password)
        instance.save()
        if role:
            instance.groups.set([Group.objects.get(name=role)])
        return instance
