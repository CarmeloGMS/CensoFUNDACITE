# Censo de Consejos Campesinos – Estado La Guaira

Monorepo:
- `backend/`  Django 5 + DRF + GeoDjango + PostGIS, JWT (djangorestframework-simplejwt)
- `web/`      Panel web: React + Vite + TypeScript + Tailwind + MapLibre GL (OSM tiles) + Recharts
- `mobile/`   App de campo: Flutter (Android), offline-first (Drift/SQLite), geolocator, flutter_map
- `docker-compose.yml`: db (postgis/postgis:16-3.4), backend (gunicorn :8000), web (nginx :8080 sirve el build y hace proxy de /api -> backend)

Los campos del censo son PROVISIONALES hasta coordinar con el Ministerio; el modelo debe ser fácil de extender.

## Catálogos (seed por data migration)
Estado La Guaira -> Municipio Vargas -> 11 parroquias:
Caraballeda, Carayaca, Carlos Soublette, Caruao, Catia La Mar, El Junko, La Guaira, Macuto, Maiquetía, Naiguatá, Urimare.
Rubros (multi): Café, Cacao, Hortalizas, Frutales, Cambur/Plátano, Aguacate, Raíces y tubérculos, Granos, Flores, Ganadería bovina, Ganadería caprina/ovina, Avicultura, Porcinos, Apicultura, Pesca artesanal, Otro.
Tenencia de la tierra (single): propia, adjudicada_inti, arrendada, comunal, ocupacion, otra.
Fuente de agua (single): rio_quebrada, naciente, pozo, acueducto, lluvia, ninguna.

## Modelos
Parroquia(id, nombre, municipio="Vargas", centroide Point 4326 nullable)
Rubro(id, nombre)
ConsejoCampesino:
- uuid (UUID, unique, generado en el cliente -> idempotencia en sync), id interno
- nombre (str, requerido), rif (str, opcional), codigo_registro (str, opcional)
- parroquia FK, sector (str), direccion (text)
- ubicacion Point(4326) requerido, precision_gps_m (float, nullable), altitud_m (float, nullable)
- fecha_constitucion (date, nullable)
- num_familias, num_hombres, num_mujeres, num_jovenes (int >=0, default 0)
- superficie_ha (decimal 10,2, nullable), tenencia_tierra (choice), fuente_agua (choice), tiene_riego (bool)
- rubros M2M Rubro
- necesidades (text), observaciones (text)
- estado choice: enviado | validado | rechazado (default enviado)
- registrado_por FK User, dispositivo_id (str), fecha_captura (datetime del cliente), creado/actualizado (auto)
Vocero (FK consejo, related_name voceros): nombre, cedula, telefono, cargo, es_principal bool
Foto (FK consejo, related_name fotos): imagen ImageField (MEDIA), descripcion, uuid único (idempotencia)

Roles (Django Groups): administrador, supervisor, encuestador.
- encuestador: crea y ve/edita solo lo suyo.
- supervisor/administrador: ve todo, cambia estado (validar/rechazar).
- administrador: gestiona usuarios.

## API (prefijo /api, JSON, auth Bearer JWT salvo login)
POST /api/auth/token/          {username,password} -> {access,refresh}
POST /api/auth/token/refresh/  {refresh} -> {access}
GET  /api/auth/me/             -> {id, username, first_name, last_name, email, rol}
GET  /api/catalogos/           -> {parroquias:[{id,nombre,municipio,centroide:[lng,lat]|null}], rubros:[{id,nombre}], tenencia_tierra:[{value,label}], fuente_agua:[{value,label}], estados:[{value,label}]}
GET  /api/consejos/            paginado (page, page_size<=200) filtros: parroquia, rubro, estado, search (nombre/rif/sector), registrado_por, fecha_desde, fecha_hasta; ordering
     item: {id, uuid, nombre, rif, codigo_registro, parroquia:{id,nombre}, sector, direccion,
            lat, lng, precision_gps_m, altitud_m, fecha_constitucion, num_familias, num_hombres, num_mujeres, num_jovenes,
            superficie_ha, tenencia_tierra, fuente_agua, tiene_riego, rubros:[{id,nombre}], necesidades, observaciones,
            estado, registrado_por:{id,username,nombre}, dispositivo_id, fecha_captura, creado, actualizado,
            voceros:[{id,nombre,cedula,telefono,cargo,es_principal}], fotos:[{id,uuid,url,descripcion}]}
     escritura: parroquia_id, rubro_ids, lat, lng, voceros (lista anidada, se reemplaza completa)
POST/GET/PATCH/DELETE /api/consejos/{id}/
POST /api/consejos/{id}/estado/  {estado} (supervisor/admin)
GET  /api/consejos/geojson/      mismos filtros, sin paginar -> FeatureCollection (props: id,nombre,parroquia,estado,num_familias,rubros)
GET  /api/consejos/export.csv    mismos filtros
POST /api/sync/consejos/         {items:[<consejo escritura con uuid>]} -> upsert por uuid; {resultados:[{uuid,id,status:"created"|"updated"|"error",errores?}]}
POST /api/consejos/{id}/fotos/   multipart (imagen, descripcion, uuid) -> idempotente por uuid
GET  /api/estadisticas/          mismos filtros -> {total, validados, pendientes(enviado), rechazados, familias, miembros, superficie_ha,
                                  por_parroquia:[{parroquia,total,familias}], por_rubro:[{rubro,total}], por_mes:[{mes:"YYYY-MM",total}],
                                  por_encuestador:[{usuario,total}]}
CRUD /api/usuarios/ (solo administrador): {id,username,first_name,last_name,email,rol,is_active,password(write-only)}
