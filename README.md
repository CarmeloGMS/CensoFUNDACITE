# Censo Campesino — Estado La Guaira

Backend del censo de Consejos Campesinos, desarrollado con Django, Django REST Framework, GeoDjango y PostGIS. La API está bajo `/api/` y entrega JSON, salvo las cargas de fotografías y la exportación CSV.

## Requisitos

- Docker y Docker Compose.
- Puertos `8000` (API) y `5432` (PostGIS) disponibles.

## Inicio rápido

Desde la raíz del repositorio:

```bash
docker compose up -d db backend
docker compose exec backend python manage.py seed_demo
```

El servicio `backend` aplica las migraciones al arrancar y expone la API en <http://localhost:8000>. Los archivos multimedia se conservan en `backend/media/`.

Para reiniciar únicamente los registros de demostración:

```bash
docker compose exec backend python manage.py seed_demo --reset
```

El comando elimina y vuelve a crear solo los consejos identificados como datos demo; los catálogos y las cuentas se conservan.

El panel web todavía no forma parte de este alcance. Cuando exista `web/Dockerfile`, se puede levantar el servicio nginx opcional así:

```bash
docker compose --profile web up -d
```

## Configuración

Compose ofrece valores locales de desarrollo. Se pueden sobrescribir con variables de entorno o un archivo `.env`:

| Variable | Valor local predeterminado | Uso |
| --- | --- | --- |
| `SECRET_KEY` | clave solo para desarrollo | Clave secreta de Django |
| `DEBUG` | `true` | Habilita modo de depuración y CORS para cualquier origen |
| `ALLOWED_HOSTS` | `localhost,127.0.0.1,backend` | Hosts permitidos |
| `POSTGRES_DB` | `censo_campesino` | Base de datos |
| `POSTGRES_USER` | `censo` | Usuario de Postgres |
| `POSTGRES_PASSWORD` | `censo` | Contraseña de Postgres |
| `POSTGRES_PORT` | `5432` | Puerto publicado de Postgres |
| `BACKEND_PORT` | `8000` | Puerto publicado de la API |
| `WEB_PORT` | `8080` | Puerto publicado por nginx con el perfil `web` |

También se puede configurar la conexión del backend con `DATABASE_URL` (por ejemplo, `postgis://usuario:clave@db:5432/censo_campesino`) o con `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST` y `POSTGRES_PORT`.

## Cuentas de demostración

| Usuario | Contraseña | Rol |
| --- | --- | --- |
| `admin` | `admin123` | `administrador` |
| `supervisor` | `supervisor123` | `supervisor` |
| `encuestador1` | `encuestador123` | `encuestador` |
| `encuestador2` | `encuestador123` | `encuestador` |

Son credenciales ficticias de desarrollo; cámbielas y configure una `SECRET_KEY` propia antes de desplegar el sistema.

## API

Las rutas de datos requieren `Authorization: Bearer <access>`. La obtención y renovación de tokens usan las credenciales o el token de renovación enviados en el cuerpo:

```http
POST /api/auth/token/
Content-Type: application/json

{"username":"admin","password":"admin123"}
```

| Ruta | Descripción |
| --- | --- |
| `POST /api/auth/token/` | Obtener tokens JWT |
| `POST /api/auth/token/refresh/` | Renovar el token de acceso |
| `GET /api/auth/me/` | Usuario autenticado y rol |
| `GET /api/catalogos/` | Parroquias, rubros y opciones de formularios |
| `GET, POST /api/consejos/` | Listar y crear consejos; admite filtros, búsqueda, orden y paginación |
| `GET, PATCH, DELETE /api/consejos/{id}/` | Consultar, editar o eliminar un consejo |
| `POST /api/consejos/{id}/estado/` | Cambiar estado (supervisor/administrador) |
| `GET /api/consejos/geojson/` | GeoJSON con los mismos filtros |
| `GET /api/consejos/export.csv` | Exportar resultados filtrados como CSV |
| `POST /api/sync/consejos/` | Sincronizar una lista de registros por UUID |
| `POST /api/consejos/{id}/fotos/` | Cargar una foto multipart e idempotente por UUID |
| `GET /api/estadisticas/` | Totales y desgloses filtrados |
| `/api/usuarios/` | CRUD de usuarios, solo para administradores |

La lista de consejos acepta `parroquia`, `rubro`, `estado`, `search`, `registrado_por`, `fecha_desde`, `fecha_hasta`, `ordering`, `page` y `page_size` (máximo 200). Los encuestadores solo consultan y modifican sus propios registros; supervisores y administradores pueden consultar todos. La sincronización informa el resultado por elemento para permitir éxitos parciales.

## Pruebas

Las pruebas de API requieren la base PostGIS del Compose:

```bash
docker compose up -d db backend
docker compose exec backend python manage.py test
```

## Datos incluidos

Una migración inicializa las 11 parroquias del municipio Vargas, sus centroides aproximados, los 16 rubros y los grupos `administrador`, `supervisor` y `encuestador`. `seed_demo` crea usuarios y 45 consejos ficticios distribuidos por parroquia.

## Aplicación móvil

La app Flutter para encuestadores se encuentra en [`mobile/`](mobile/README.md). Está diseñada para Android y trabajo en campo con conectividad intermitente: conserva los registros localmente y sincroniza por lotes cuando vuelve la conexión.

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

En el emulador Android se usa `http://10.0.2.2:8000` para acceder al backend del host. En un teléfono físico, configure en el inicio la URL HTTP de la máquina que ejecuta la API.
