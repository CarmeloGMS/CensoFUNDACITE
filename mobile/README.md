# Aplicación móvil Censo Campesino

Aplicación Flutter para el levantamiento de consejos campesinos en campo. Los borradores, registros y fotos se conservan localmente; la sincronización con la API se puede reintentar cuando haya conectividad.

## Requisitos

- Flutter estable y Android SDK con las licencias aceptadas.
- Android 8.0 (API 26) o superior.
- Backend del proyecto accesible desde el teléfono o emulador.

## Preparar y ejecutar

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Para compilar un APK de depuración o de distribución:

```bash
flutter build apk --debug
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/`. La versión inicial de prototipo usa la firma de depuración de Android para `--release`; configure una firma propia antes de publicar en una tienda.

## Configurar el servidor

La URL inicial es `http://10.0.2.2:8000`, que permite al emulador Android comunicarse con el backend del equipo anfitrión. Para este alias del emulador, la app envía `Host: localhost` para ser compatible con la lista `ALLOWED_HOSTS` predeterminada del backend; las URL personalizadas conservan su host. En un teléfono real, abra **Configurar servidor** en el inicio e indique la dirección LAN del equipo que ejecuta la API, por ejemplo `http://192.168.1.20:8000`. La URL queda guardada en el dispositivo.

El acceso inicial requiere conexión para autenticar al encuestador y descargar `/api/auth/me/` y `/api/catalogos/`. Después, la sesión y los catálogos quedan almacenados localmente. Los registros se guardan sin conexión y se sincronizan por lotes de hasta 20 elementos al recuperar la conectividad o al tocar **Sincronizar ahora**.

Para desarrollo local, las cuentas de demostración están documentadas en el README raíz. No use credenciales de demostración en despliegues reales. El prototipo permite HTTP en redes locales; utilice HTTPS en una instalación de producción.

## Instalar el APK

Active la instalación de aplicaciones para desarrollo en el teléfono y copie el APK, o instálelo con ADB:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

La aplicación solicita permisos de ubicación y cámara cuando se usan esas funciones. Si se deniega la ubicación, se puede ajustar el punto tocando el mapa; para tomar fotos se puede usar la cámara o elegir una imagen de la galería.
