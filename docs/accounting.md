# Módulo de Contabilidad

El corazón financiero del sistema, encargado de la integridad de los datos contables.

## Componentes
*   **Catálogo de Cuentas:** Estructura jerárquica de cuentas.
*   **Asientos Contables:** Generados automáticamente por acciones del sistema (compras, pagos, cobros).
*   **Centros de Costo:** Vinculación de movimientos contables con proyectos específicos.

## Automatización
El `AsientoService` en el backend es el encargado de generar las partidas doble para cada transacción, asegurando que el debe y haber cuadren antes de persistir.
