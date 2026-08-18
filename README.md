# ALEVET Móvil

App móvil en Flutter — panel de administración de **Agroveterinaria ALEVET**.

Es el panel de administrador en versión celular: permite gestionar inventario,
pedidos, ventas y colaboradores desde el teléfono, sin depender del dashboard
web. Funciona como un cliente de la misma API que usa el sitio web público.

> La tienda online para clientes finales es un proyecto aparte
> ([ALIVETagroveterinaria](https://alivetagroveterinaria-web.onrender.com)).
> Esta app consume la **misma API y base de datos**, pero está pensada
> para el administrador/colaboradores, no para el cliente final.

## Funcionalidades

- Inicio de sesión con correo y contraseña
- Dashboard con resumen general
- Gestión de pedidos
- Productos con bajo stock
- Productos próximos a vencer
- Registro de nuevos productos (con imagen)
- Registro de nuevos colaboradores
- Escaneo de código de barras
- Gráfico de ventas
- Detalle de producto
- Perfil del usuario logueado

## Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada de la app
├── models/                    # Clases que mapean las respuestas JSON del backend
├── services/                  # Llamadas HTTP a la API (Dio)
├── screens/                   # Una pantalla por archivo
└── widgets/                   # Componentes de UI reutilizables
```

## Backend

Esta app consume la API REST en:

```
https://alivetagroveterinaria-web.onrender.com/api
```

La configuración de endpoints está centralizada en
[`lib/services/api_config.dart`](lib/services/api_config.dart).

## Cómo correr el proyecto

```bash
flutter pub get
flutter run
```

## Stack

- Flutter / Dart
- [dio](https://pub.dev/packages/dio) — cliente HTTP
- [shared_preferences](https://pub.dev/packages/shared_preferences) — sesión local
- [fl_chart](https://pub.dev/packages/fl_chart) — gráficos de ventas
- [mobile_scanner](https://pub.dev/packages/mobile_scanner) — escaneo de código de barras
- [image_picker](https://pub.dev/packages/image_picker) — fotos de producto
