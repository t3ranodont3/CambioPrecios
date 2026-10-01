# Change Log

## Unreleased
- Implementación de almacenamiento multiusuario: cajas por usuario (products_<usuario>, reports_<usuario>, config_<usuario>) y switching de usuario que cierra cajas antiguas y abre las nuevas.
- Restaurar desde JSON: lectura basada en bytes para Web; refresca la UI sin cerrar la pantalla.
- Importación de catálogo y último reporte: compatible con Windows, Android y Web; uso consistente de bytes cuando es posible.
- Añadido campo Fracción (Fraccion) en la vista de catálogo para distinguir productos similares.
- Botones y textos de UI actualizados para claridad (Editar productos, Eliminar Producto, Añadir otro producto).
- Mejoras en flujo de añadir producto: cuando se detecta un producto existente, opción para añadir otro producto continúa el flujo de búsqueda.
- Tests iniciales: se añadió test de unidad para ReportRecord y scaffolding para tests de UI (integration tests).

## Próximos cambios planeados
- Añadir tests de UI más completos (integración) para flujos clave.
- Refinar flujo de login multiusuario y manejo de locks de Hive.
- Añadir guía de usuario y documentación de instalación/uso.
