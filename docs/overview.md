# Documentación General del Sistema de Construcción

Este directorio contiene la documentación técnica y funcional del sistema para asegurar la continuidad del desarrollo entre diferentes agentes.

## Arquitectura del Sistema
*   **Backend:** Laravel 10+ (API REST v1).
*   **Frontend:** Flutter (Mobile/Desktop).
*   **Base de Datos:** Relacional (PostgreSQL).

## Módulos Principales
1.  **[Proyectos](projects.md):** Gestión de obras, presupuestos, partidas y subpartidas.
2.  **[Contabilidad](accounting.md):** Catálogo de cuentas, asientos automáticos, estados financieros y bancos.
3.  **[Compras e Inventario](inventory.md):** Gestión de proveedores, órdenes de compra, recepciones y stock en obra.
4.  **[Finanzas](finance.md):** Cuentas por cobrar (clientes), cuentas por pagar (proveedores) y flujo de caja.

## Reglas Generales
*   Todos los montos incluyen ITBIS (18%) de forma calculada en el backend.
*   Las transacciones financieras generan asientos contables automáticos basados en el catálogo de cuentas configurado.
*   El sistema utiliza un prefijo `/api/v1/` para todas las rutas de la API.
