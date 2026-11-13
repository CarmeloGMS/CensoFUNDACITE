import uuid
from io import BytesIO
from tempfile import TemporaryDirectory

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.contrib.gis.geos import Point
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from PIL import Image
from rest_framework.test import APIClient

from censo.models import ConsejoCampesino, Foto, Parroquia, Rubro

User = get_user_model()


class ApiTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.parroquia = Parroquia.objects.get(nombre="Catia La Mar")
        cls.rubro = Rubro.objects.get(nombre="Cacao")
        cls.admin = User.objects.create_superuser(
            username="api-admin", email="admin@example.test", password="admin-pass-123"
        )
        cls.supervisor = User.objects.create_user(username="api-supervisor", password="super-pass-123")
        cls.encuestador = User.objects.create_user(username="api-encuestador", password="enc-pass-123")
        cls.otro_encuestador = User.objects.create_user(username="api-otro", password="other-pass-123")
        cls.supervisor.groups.add(Group.objects.get(name="supervisor"))
        cls.encuestador.groups.add(Group.objects.get(name="encuestador"))
        cls.otro_encuestador.groups.add(Group.objects.get(name="encuestador"))

    def use_user(self, user):
        self.client = APIClient()
        self.client.force_authenticate(user=user)

    def council_payload(self, **overrides):
        payload = {
            "uuid": str(uuid.uuid4()),
            "nombre": "Consejo Campesino Cacao de Chuao",
            "rif": "J-12345678-9",
            "codigo_registro": "LG-2025-001",
            "parroquia_id": self.parroquia.id,
            "sector": "El Topo",
            "direccion": "Vía agrícola, sector El Topo",
            "lat": 10.55,
            "lng": -67.02,
            "precision_gps_m": 4.5,
            "altitud_m": 460,
            "num_familias": 20,
            "num_hombres": 24,
            "num_mujeres": 28,
            "num_jovenes": 12,
            "superficie_ha": "12.50",
            "tenencia_tierra": "comunal",
            "fuente_agua": "rio_quebrada",
            "tiene_riego": True,
            "rubro_ids": [self.rubro.id],
            "necesidades": "Semillas y herramientas",
            "observaciones": "Datos de prueba",
            "dispositivo_id": "flutter-test",
            "voceros": [
                {
                    "nombre": "María González",
                    "cedula": "V-12.345.678",
                    "telefono": "0414-123-4567",
                    "cargo": "Vocera principal",
                    "es_principal": True,
                }
            ],
        }
        payload.update(overrides)
        return payload

    def create_council(self, user=None, **overrides):
        nombre = overrides.pop("nombre", "Consejo campesino de prueba")
        council = ConsejoCampesino.objects.create(
            uuid=uuid.uuid4(),
            nombre=nombre,
            parroquia=self.parroquia,
            ubicacion=Point(-67.02, 10.55, srid=4326),
            registrado_por=user or self.encuestador,
            **overrides,
        )
        council.rubros.add(self.rubro)
        return council

    def test_token_and_me_include_group_role(self):
        self.client = APIClient()
        response = self.client.post(
            "/api/auth/token/",
            {"username": "api-encuestador", "password": "enc-pass-123"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {response.data['access']}")
        me = self.client.get("/api/auth/me/")
        self.assertEqual(me.status_code, 200)
        self.assertEqual(me.data["rol"], "encuestador")

    def test_catalogos_contain_spec_values(self):
        self.use_user(self.admin)
        response = self.client.get("/api/catalogos/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data["parroquias"]), 11)
        self.assertEqual(response.data["parroquias"][4]["nombre"], "Catia La Mar")
        self.assertEqual(response.data["parroquias"][4]["centroide"], [-67.03, 10.6])
        self.assertEqual(len(response.data["rubros"]), 16)
        self.assertEqual(
            {choice["value"] for choice in response.data["tenencia_tierra"]},
            {"propia", "adjudicada_inti", "arrendada", "comunal", "ocupacion", "otra"},
        )

    def test_create_council_with_voceros_and_rubros(self):
        self.use_user(self.encuestador)
        response = self.client.post("/api/consejos/", self.council_payload(), format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["parroquia"], {"id": self.parroquia.id, "nombre": "Catia La Mar"})
        self.assertEqual(response.data["rubros"], [{"id": self.rubro.id, "nombre": "Cacao"}])
        self.assertEqual(response.data["voceros"][0]["cedula"], "V-12.345.678")
        self.assertEqual(response.data["registrado_por"]["username"], "api-encuestador")
        self.assertEqual(response.data["lat"], 10.55)
        self.assertEqual(response.data["lng"], -67.02)

    def test_encuestador_only_sees_own_records(self):
        own = self.create_council(user=self.encuestador)
        self.create_council(user=self.otro_encuestador, nombre="Registro de otra persona")
        self.use_user(self.encuestador)
        response = self.client.get("/api/consejos/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([row["id"] for row in response.data["results"]], [own.id])
        detail = self.client.get(f"/api/consejos/{own.id}/")
        self.assertEqual(detail.status_code, 200)

    def test_supervisor_changes_state_and_encuestador_is_forbidden(self):
        council = self.create_council()
        self.use_user(self.encuestador)
        denied = self.client.post(
            f"/api/consejos/{council.id}/estado/", {"estado": "validado"}, format="json"
        )
        self.assertEqual(denied.status_code, 403)
        self.use_user(self.supervisor)
        changed = self.client.post(
            f"/api/consejos/{council.id}/estado/", {"estado": "validado"}, format="json"
        )
        self.assertEqual(changed.status_code, 200, changed.data)
        council.refresh_from_db()
        self.assertEqual(council.estado, "validado")

    def test_sync_same_uuid_creates_then_updates_without_duplicate(self):
        self.use_user(self.encuestador)
        payload = self.council_payload()
        response = self.client.post(
            "/api/sync/consejos/", {"items": [payload, payload]}, format="json"
        )
        self.assertEqual(response.status_code, 200, response.data)
        results = response.data["resultados"]
        self.assertEqual([item["status"] for item in results], ["created", "updated"])
        self.assertEqual(results[0]["id"], results[1]["id"])
        self.assertEqual(ConsejoCampesino.objects.filter(uuid=payload["uuid"]).count(), 1)

    def test_sync_rejects_encuestador_overwriting_another_users_record(self):
        council = self.create_council(user=self.otro_encuestador)
        payload = self.council_payload(uuid=str(council.uuid), nombre="Cambio no autorizado")
        self.use_user(self.encuestador)
        response = self.client.post("/api/sync/consejos/", {"items": [payload]}, format="json")
        self.assertEqual(response.data["resultados"][0]["status"], "error")
        council.refresh_from_db()
        self.assertNotEqual(council.nombre, "Cambio no autorizado")

    def test_geojson_statistics_and_csv_shapes(self):
        council = self.create_council(num_familias=7, num_hombres=10, num_mujeres=11, num_jovenes=4)
        self.use_user(self.admin)
        geojson = self.client.get("/api/consejos/geojson/")
        self.assertEqual(geojson.status_code, 200)
        self.assertEqual(geojson.data["type"], "FeatureCollection")
        self.assertEqual(geojson.data["features"][0]["geometry"]["coordinates"], [-67.02, 10.55])
        self.assertEqual(geojson.data["features"][0]["properties"]["id"], council.id)
        stats = self.client.get("/api/estadisticas/")
        self.assertEqual(stats.status_code, 200)
        self.assertEqual(
            set(stats.data),
            {
                "total",
                "validados",
                "pendientes",
                "rechazados",
                "familias",
                "miembros",
                "superficie_ha",
                "por_parroquia",
                "por_rubro",
                "por_mes",
                "por_encuestador",
                "sanidad_produccion",
            },
        )
        self.assertEqual(stats.data["total"], 1)
        csv_response = self.client.get("/api/consejos/export.csv")
        self.assertEqual(csv_response.status_code, 200)
        self.assertIn("consejos.csv", csv_response["Content-Disposition"])

    def test_photo_upload_is_idempotent_by_uuid(self):
        temporary_media = TemporaryDirectory()
        self.addCleanup(temporary_media.cleanup)
        settings_override = override_settings(MEDIA_ROOT=temporary_media.name)
        settings_override.enable()
        self.addCleanup(settings_override.disable)

        council = self.create_council()
        image_buffer = BytesIO()
        Image.new("RGB", (2, 2), color="green").save(image_buffer, format="JPEG")
        upload = SimpleUploadedFile("parcela.jpg", image_buffer.getvalue(), content_type="image/jpeg")
        photo_uuid = str(uuid.uuid4())
        self.use_user(self.encuestador)
        first = self.client.post(
            f"/api/consejos/{council.id}/fotos/",
            {"imagen": upload, "descripcion": "Parcela", "uuid": photo_uuid},
            format="multipart",
        )
        self.assertEqual(first.status_code, 201, first.data)
        self.assertEqual(set(first.data), {"id", "uuid", "url", "descripcion"})
        second = self.client.post(
            f"/api/consejos/{council.id}/fotos/",
            {"uuid": photo_uuid},
            format="multipart",
        )
        self.assertEqual(second.status_code, 200, second.data)
        self.assertEqual(Foto.objects.filter(uuid=photo_uuid).count(), 1)


class SanidadProduccionTests(TestCase):
    def setUp(self):
        for role in ("administrador", "supervisor", "encuestador"):
            Group.objects.get_or_create(name=role)
        self.admin = User.objects.create_user("admin_sp", password="clave-segura-1")
        self.admin.groups.add(Group.objects.get(name="administrador"))
        self.client = APIClient()
        self.client.force_authenticate(self.admin)
        self.parroquia = Parroquia.objects.order_by("id").first()

    def _payload(self, **extra):
        data = {
            "nombre": "Consejo Sanidad",
            "parroquia_id": self.parroquia.id,
            "lat": 10.58,
            "lng": -66.9,
            "enfermedades": ["hongos"],
            "plagas": ["insectos", "nematodos"],
            "destino_produccion": ["consumo_familiar", "venta_local_comunal"],
            "tipos_cultivo": ["asociado"],
            "produccion_animal": ["avicola", "apicultura"],
            "requerimientos": "Semillas certificadas",
        }
        data.update(extra)
        return data

    def test_admin_registra_y_estadisticas_cuentan_opciones(self):
        response = self.client.post("/api/consejos/", self._payload(), format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["plagas"], ["insectos", "nematodos"])
        self.assertEqual(response.data["registrado_por"]["username"], "admin_sp")

        stats = self.client.get("/api/estadisticas/").data["sanidad_produccion"]
        plagas = {item["value"]: item["total"] for item in stats["plagas"]}
        self.assertEqual(plagas, {"insectos": 1, "acaros": 0, "nematodos": 1})
        self.assertEqual(len(stats["produccion_animal"]), 7)

        filtrado = self.client.get("/api/consejos/?animal=apicultura").data
        self.assertEqual(filtrado["count"], 1)
        self.assertEqual(self.client.get("/api/consejos/?animal=bovino").data["count"], 0)

        catalogos = self.client.get("/api/catalogos/").data
        self.assertEqual([o["value"] for o in catalogos["tipos_cultivo"]], ["monocultivo", "rotativo", "asociado"])

    def test_opcion_invalida_es_rechazada(self):
        response = self.client.post("/api/consejos/", self._payload(plagas=["langosta"]), format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("plagas", response.data)
