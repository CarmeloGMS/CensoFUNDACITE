from django.contrib import admin

from .models import ConsejoCampesino, Foto, Parroquia, Rubro, Vocero


@admin.register(ConsejoCampesino)
class ConsejoCampesinoAdmin(admin.ModelAdmin):
    list_display = ("nombre", "parroquia", "estado", "registrado_por", "fecha_captura")
    list_filter = ("estado", "parroquia")
    search_fields = ("nombre", "rif", "sector")


admin.site.register((Parroquia, Rubro, Vocero, Foto))
