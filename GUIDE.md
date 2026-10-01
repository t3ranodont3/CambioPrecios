Guía de Usuario - CambioPreciosDIGEMID (Flutter)

- Requisitos
  - Plataformas: Windows, Android, Web (navegadores modernos)
- Flujo básico
  1. Iniciar sesión en la app. Se crea un usuario local; los datos quedan aislados por usuario.
  2. Importar catálogo de productos: usa la opción Importar catálogo y selecciona el archivo Excel; el app guardará el último archivo por usuario.
  3. Importar último reporte: la app carga el último reporte guardado en el box de config por usuario.
  4. Editar productos: abre Editar productos para ver la lista de productos; puedes eliminar, editar precios, o añadir nuevos productos desde el catálogo.
  5. Añadir producto: al abrir el diálogo del catálogo, puedes buscar productos; si ya existe, se pregunta si quieres cambiar precios o añadir otro producto y continuar.
  6. Restaurar desde JSON: desde la opción Restore Session (JSON) se puede traer de vuelta una sesión previamente guardada. En Web se leen bytes para compatibilidad.

- Multiusuario
  - Cada usuario tiene sus propias cajas Hive: productos_<usuario>, reports_<usuario>, config_<usuario>.
  - Al iniciar sesión con un usuario distinto, se cierran las cajas del usuario anterior y se abren las del nuevo.

- Importar/Exportar
  - Importar Catálogo: se guarda en la caja de productos del usuario actual; el path se guarda por usuario.
  - Importar Último Reporte: se guarda en la caja de reports del usuario actual.
  - Exportar sesión (JSON): guarda el estado de la sesión actual en un archivo JSON.
  - Restaurar from JSON: se carga el JSON en la caja de reports del usuario actual y la UI se refresca.

- Casos comunes y solución de problemas
  - Si aparece un error de Hive lock, cerrar todas las instancias de la app y eliminar cualquier *.lock en Documentos.
  - En Web, si hay problemas con Namespace, usar la lectura de bytes para JSON y evitar path del FS.

- Atajos de UI
  - Botón de edición ahora dice: Editar productos
- Contenido de los cambios recientes y cómo probarlos lo puedes encontrar en CHANGELOG.md.
