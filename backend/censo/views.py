import csv
import uuid as uuid_module
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.contrib.gis.geos import Point
from django.db.models import Count, Sum
from django.db.models.functions import TruncMonth
from django.http import HttpResponse
from django_filters import rest_framework as filters
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import ConsejoCampesino, Foto, Parroquia, Rubro
from .permissions import IsAdministrator, IsConsejoReader, user_role
from .serializers import ConsejoSerializer, FotoSerializer, UsuarioSerializer

User = get_user_model()


class ConsejoFilter(filters.FilterSet):
    rubro = filters.NumberFilter(field_name="rubros__id")
    fecha_desde = filters.DateFilter(field_name="fecha_captura", lookup_expr="date__gte")
    fecha_hasta = filters.DateFilter(field_name="fecha_captura", lookup_expr="date__lte")

    class Meta:
        model = ConsejoCampesino
        fields = ("parroquia", "rubro", "estado", "registrado_por")


class MeView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        user = request.user
        return Response(
            {
                "id": user.id,
                "username": user.username,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "email": user.email,
                "rol": user_role(user),
            }
        )


class CatalogosView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        parroquias = []
        for parroquia in Parroquia.objects.order_by("id"):
            point = parroquia.centroide
            parroquias.append(
                {
                    "id": parroquia.id,
                    "nombre": parroquia.nombre,
                    "municipio": parroquia.municipio,
                    "centroide": [point.x, point.y] if point else None,
                }
            )
        return Response(
            {
                "parroquias": parroquias,
                "rubros": [{"id": rubro.id, "nombre": rubro.nombre} for rubro in Rubro.objects.order_by("id")],
                "tenencia_tierra": [
                    {"value": value, "label": label}
                    for value, label in ConsejoCampesino.TenenciaTierra.choices
                ],
                "fuente_agua": [
                    {"value": value, "label": label}
                    for value, label in ConsejoCampesino.FuenteAgua.choices
                ],
                "estados": [
                    {"value": value, "label": label} for value, label in ConsejoCampesino.Estado.choices
                ],
            }
        )


class ConsejoViewSet(viewsets.ModelViewSet):
    serializer_class = ConsejoSerializer
    permission_classes = (IsConsejoReader,)
    filterset_class = ConsejoFilter
    search_fields = ("nombre", "rif", "sector")
    ordering_fields = ("nombre", "fecha_captura", "creado", "actualizado", "estado")
    ordering = ("-fecha_captura", "-id")
    parser_classes = (JSONParser, MultiPartParser, FormParser)

    def get_queryset(self):
        queryset = ConsejoCampesino.objects.select_related("parroquia", "registrado_por").prefetch_related(
            "rubros", "voceros", "fotos"
        )
        if user_role(self.request.user) not in {"administrador", "supervisor"}:
            queryset = queryset.filter(registrado_por=self.request.user)
        return queryset

    def perform_create(self, serializer):
        serializer.save(registrado_por=self.request.user)

    @action(detail=False, methods=["get"], url_path="geojson")
    def geojson(self, request):
        features = []
        for consejo in self.filter_queryset(self.get_queryset()):
            features.append(
                {
                    "type": "Feature",
                    "geometry": {
                        "type": "Point",
                        "coordinates": [consejo.ubicacion.x, consejo.ubicacion.y],
                    },
                    "properties": {
                        "id": consejo.id,
                        "nombre": consejo.nombre,
                        "parroquia": consejo.parroquia.nombre,
                        "estado": consejo.estado,
                        "num_familias": consejo.num_familias,
                        "rubros": [rubro.nombre for rubro in consejo.rubros.all()],
                    },
                }
            )
        return Response({"type": "FeatureCollection", "features": features})

    @action(detail=False, methods=["get"], url_path="export.csv")
    def export_csv(self, request):
        response = HttpResponse(content_type="text/csv; charset=utf-8")
        response["Content-Disposition"] = 'attachment; filename="consejos.csv"'
        response.write("\ufeff")
        writer = csv.writer(response)
        writer.writerow(
            ["id", "uuid", "nombre", "parroquia", "sector", "lat", "lng", "estado", "num_familias"]
        )
        for consejo in self.filter_queryset(self.get_queryset()):
            writer.writerow(
                [
                    consejo.id,
                    consejo.uuid,
                    consejo.nombre,
                    consejo.parroquia.nombre,
                    consejo.sector,
                    consejo.ubicacion.y,
                    consejo.ubicacion.x,
                    consejo.estado,
                    consejo.num_familias,
                ]
            )
        return response

    @action(detail=True, methods=["post"], url_path="estado")
    def cambiar_estado(self, request, pk=None):
        consejo = self.get_object()
        if user_role(request.user) not in {"administrador", "supervisor"}:
            return Response(
                {"detail": "Solo supervisores y administradores pueden cambiar el estado."},
                status=status.HTTP_403_FORBIDDEN,
            )
        estado = request.data.get("estado")
        valid_states = {value for value, _ in ConsejoCampesino.Estado.choices}
        if estado not in valid_states:
            raise ValidationError({"estado": f"Debe ser uno de: {', '.join(sorted(valid_states))}."})
        consejo.estado = estado
        consejo.save(update_fields=["estado", "actualizado"])
        return Response(ConsejoSerializer(consejo, context=self.get_serializer_context()).data)

    @action(
        detail=True,
        methods=["post"],
        url_path="fotos",
        parser_classes=(MultiPartParser, FormParser),
    )
    def subir_foto(self, request, pk=None):
        consejo = self.get_object()
        raw_uuid = request.data.get("uuid")
        if not raw_uuid:
            raise ValidationError({"uuid": "Este campo es requerido."})
        try:
            foto_uuid = uuid_module.UUID(str(raw_uuid))
        except (TypeError, ValueError, AttributeError):
            raise ValidationError({"uuid": "Ingrese un UUID válido."})

        existing = Foto.objects.filter(uuid=foto_uuid).first()
        if existing:
            if existing.consejo_id != consejo.id:
                raise ValidationError({"uuid": "Este UUID ya pertenece a otra fotografía."})
            return Response(
                FotoSerializer(existing, context=self.get_serializer_context()).data,
                status=status.HTTP_200_OK,
            )

        serializer = FotoSerializer(data=request.data, context=self.get_serializer_context())
        serializer.is_valid(raise_exception=True)
        foto = serializer.save(consejo=consejo)
        return Response(
            FotoSerializer(foto, context=self.get_serializer_context()).data,
            status=status.HTTP_201_CREATED,
        )


class SyncConsejosView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        items = request.data.get("items")
        if not isinstance(items, list):
            raise ValidationError({"items": "Debe ser una lista."})

        results = []
        role = user_role(request.user)
        for item in items:
            if not isinstance(item, dict):
                results.append({"uuid": None, "id": None, "status": "error", "errores": {"item": "Debe ser un objeto."}})
                continue
            raw_uuid = item.get("uuid")
            try:
                item_uuid = uuid_module.UUID(str(raw_uuid))
            except (TypeError, ValueError, AttributeError):
                results.append(
                    {"uuid": raw_uuid, "id": None, "status": "error", "errores": {"uuid": "Ingrese un UUID válido."}}
                )
                continue

            existing = ConsejoCampesino.objects.filter(uuid=item_uuid).first()
            if existing and role not in {"administrador", "supervisor"} and existing.registrado_por_id != request.user.id:
                results.append(
                    {
                        "uuid": str(item_uuid),
                        "id": existing.id,
                        "status": "error",
                        "errores": {"detail": "No puede modificar un registro de otro encuestador."},
                    }
                )
                continue

            serializer = ConsejoSerializer(
                existing,
                data=item,
                partial=existing is not None,
                context={"request": request},
            )
            if not serializer.is_valid():
                results.append(
                    {
                        "uuid": str(item_uuid),
                        "id": existing.id if existing else None,
                        "status": "error",
                        "errores": serializer.errors,
                    }
                )
                continue
            consejo = serializer.save(**({"registrado_por": request.user} if existing is None else {}))
            results.append(
                {
                    "uuid": str(item_uuid),
                    "id": consejo.id,
                    "status": "updated" if existing else "created",
                }
            )
        return Response({"resultados": results})


class EstadisticasView(APIView):
    permission_classes = (IsAuthenticated,)

    def get(self, request):
        view = ConsejoViewSet()
        view.request = request
        view.format_kwarg = None
        queryset = view.filter_queryset(view.get_queryset())

        sums = queryset.aggregate(
            familias=Sum("num_familias"),
            hombres=Sum("num_hombres"),
            mujeres=Sum("num_mujeres"),
            jovenes=Sum("num_jovenes"),
            superficie_ha=Sum("superficie_ha"),
        )
        total = queryset.count()
        por_parroquia = list(
            queryset.values("parroquia__nombre")
            .annotate(total=Count("id"), familias=Sum("num_familias"))
            .order_by("parroquia__nombre")
        )
        por_rubro = list(
            queryset.values("rubros__nombre")
            .annotate(total=Count("id", distinct=True))
            .filter(rubros__nombre__isnull=False)
            .order_by("rubros__nombre")
        )
        por_mes = list(
            queryset.annotate(mes=TruncMonth("fecha_captura"))
            .values("mes")
            .annotate(total=Count("id"))
            .order_by("mes")
        )
        por_encuestador = list(
            queryset.values("registrado_por__username")
            .annotate(total=Count("id"))
            .order_by("registrado_por__username")
        )

        return Response(
            {
                "total": total,
                "validados": queryset.filter(estado=ConsejoCampesino.Estado.VALIDADO).count(),
                "pendientes": queryset.filter(estado=ConsejoCampesino.Estado.ENVIADO).count(),
                "rechazados": queryset.filter(estado=ConsejoCampesino.Estado.RECHAZADO).count(),
                "familias": sums["familias"] or 0,
                "miembros": (sums["hombres"] or 0) + (sums["mujeres"] or 0) + (sums["jovenes"] or 0),
                "superficie_ha": sums["superficie_ha"] or Decimal("0.00"),
                "por_parroquia": [
                    {
                        "parroquia": row["parroquia__nombre"],
                        "total": row["total"],
                        "familias": row["familias"] or 0,
                    }
                    for row in por_parroquia
                ],
                "por_rubro": [
                    {"rubro": row["rubros__nombre"], "total": row["total"]} for row in por_rubro
                ],
                "por_mes": [
                    {"mes": row["mes"].strftime("%Y-%m"), "total": row["total"]} for row in por_mes
                ],
                "por_encuestador": [
                    {"usuario": row["registrado_por__username"], "total": row["total"]}
                    for row in por_encuestador
                ],
            }
        )


class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = User.objects.prefetch_related("groups").order_by("username")
    serializer_class = UsuarioSerializer
    permission_classes = (IsAdministrator,)
