# Módulo de Inventario y Recepción

Este módulo gestiona el ciclo de vida de los materiales desde su compra hasta su consumo en los proyectos.

## Flujo de Trabajo
1.  **Compras:** Registro de facturas de proveedores.
2.  **Recepción:** Confirmación de llegada de materiales a la obra.
3.  **Inventario:** Seguimiento del stock por proyecto.
4.  **Consumo:** Registro de materiales utilizados en las partidas del proyecto.

## Lógica de Negocio (Mejorada)
*   **Recepciones Parciales:** El sistema permite recibir cantidades menores a las compradas. Se registra exactamente lo que llega a la obra.
*   **Seguimiento:** Cada línea de la compra rastrea su `cantidad_recibida`. La compra permanece en estado `Parcial` hasta que todos los materiales han sido recibidos al 100%.
*   **Estados de Compra:** `Pendiente`, `Pagado`, `Parcial`, `Recibido`.
*   **Costo:** El inventario rastrea el stock físico por proyecto, valorizado al costo de adquisición de las compras recibidas.

## Referencia Técnica
*   **Endpoints:**
    *   `GET /api/v1/compras-pendientes`: Compras listas para recibir.
    *   `POST /api/v1/recepciones`: Registrar entrada a inventario.
*   **Modelos:** `Compra`, `Recepcion`, `Inventario`, `Material`.
