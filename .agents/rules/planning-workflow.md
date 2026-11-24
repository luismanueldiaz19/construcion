<!-- # Regla de Planificación Obligatoria (Planning & Approval Workflow)

Para cualquier tarea en este proyecto que implique crear, modificar o eliminar código o estructura de archivos, el asistente DEBE seguir este protocolo:

1. **Generar Plan Primero (Artifact con Feedback)**:
   - Antes de modificar código, genera SIEMPRE un documento de plan en la carpeta de artefactos utilizando `write_file` con:
     ```json
     "ArtifactMetadata": {
       "RequestFeedback": true,
       "UserFacing": true,
       "Summary": "Resumen detallado del plan"
     }
     ```
   - El plan debe detallar:
     - Objetivos y análisis del cambio.
     - Archivos que serán creados, editados o eliminados.
     - Pasos y cronograma de ejecución.
     - Cumplimiento de las skills vigentes en `.agents/skills` (`flutter-clean-reusable-ui`, `flutter-small-widgets`, `laravel-module-pattern`).

2. **Esperar Aprobación ("Proceed")**:
   - Con `RequestFeedback: true`, la interfaz presentará al usuario el botón interactivo "Proceed".
   - El asistente NO debe tocar ningún archivo de código hasta que el usuario pulse "Proceed" o envíe su aprobación por escrito.

3. **Ejecución Post-Aprobación**:
   - Una vez aprobado el plan, ejecuta las modificaciones por fases organizadas, verificando con análisis estático (`dart analyze` o comandos pertinentes).

4. **Excepciones**:
   - Consultas de sólo lectura, aclaraciones técnicas o cuando el usuario instruya explícitamente ejecutar un cambio directo sin plan. -->
