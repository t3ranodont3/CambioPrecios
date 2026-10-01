# appnew_0 (CambioPreciosDIGEMID)

Aplicación Flutter creada para el Ministerio de Salud del Perú (MINSA) a
través de DIGEMID, destinada a facilitar la gestión y actualización de
precios del Observatorio Peruano de Productos Farmacéuticos (OPM).

## Objetivo

Permitir que el personal autorizado cargue catálogos y reportes de precios
en formato Excel, trabaje offline sobre esos datos y genere un reporte en
CSV según la especificación del manual (ver `Manual de Usuario carga
archivo excel4_3_2026.pdf`). La app también almacena la configuración de
usuario y credenciales de acceso.

## Funcionalidades principales

1. **Autenticación local** – ingreso con usuario y contraseña. Los datos se
   guardan en almacenamiento local para re‑uso.
2. **Carga de archivos** – importación de catálogo de productos y último
   reporte en Excel mediante el selector de archivos.
3. **Edición offline** – listado de registros de reporte con posibilidad de
   agregar, modificar y eliminar precios.
4. **Exportación CSV** – generación de un archivo CSV preparado para ser
   procesado según el procedimiento oficial.

## Estructura del proyecto

- `lib/main.dart` – inicialización y rutas.
- `lib/src/screens` – pantallas de login, importación, edición y exportación.
- `lib/src/services` – lógica de autenticación, almacenamiento y archivos.
- `lib/src/models` – definiciones de datos (`Product`, `ReportRecord`, etc.).

## Dependencias destacadas

- `shared_preferences`, `hive` – almacenamiento local.
- `file_picker` – selección de archivos en dispositivos móviles/desktop.
- `excel`, `csv` – lectura de archivos Excel y generación de CSV.

## Notas de despliegue

El código actual es únicamente un prototipo. Antes de compilar para
producción es necesario:

- Ajustar permisos de almacenamiento para las plataformas objetivo.
- Validar el formato específico de Excel y los encabezados según el manual.
- Añadir análisis de errores y UX más detallado.

Información adicional sobre el formato CSV se encuentra en el manual
incluido en la raíz del proyecto.
## Guía rápida y Cambios
- Ver Guía de usuario: GUIDE.md
- Ver cambios: CHANGELOG.md
