from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from censo.views import (
    CatalogosView,
    ConsejoViewSet,
    EstadisticasView,
    MeView,
    SyncConsejosView,
    UsuarioViewSet,
)

router = DefaultRouter()
router.register("consejos", ConsejoViewSet, basename="consejo")
router.register("usuarios", UsuarioViewSet, basename="usuario")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/auth/me/", MeView.as_view(), name="me"),
    path("api/catalogos/", CatalogosView.as_view(), name="catalogos"),
    path("api/sync/consejos/", SyncConsejosView.as_view(), name="sync_consejos"),
    path("api/estadisticas/", EstadisticasView.as_view(), name="estadisticas"),
    path("api/consejos/export.csv", ConsejoViewSet.as_view({"get": "export_csv"}), name="consejos_export_csv"),
    path("api/", include(router.urls)),
]

if settings.MEDIA_URL:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
