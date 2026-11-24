---
name: flutter-clean-reusable-ui
description: >-
  Use this skill when creating, refactoring, or reviewing Flutter and Dart code to
  eliminate code bloat and duplication. Enforces Clean Architecture, DRY principles,
  reusable core UI components (buttons, dropdowns, inputs, date pickers), centralized
  formatters (dates, currency, numbers), and compact UI density rules.
---

# Flutter Clean Architecture & Reusable Compact UI

Enforce clean code, eliminate boilerplate and duplicated UI logic, and maintain a consistent, compact design system across Flutter applications.

## When to Use

- Creating new screens, dialogs, or complex forms.
- Refactoring bloated widgets, repeated `InputDecoration`, duplicated button styles, or repeated dialog calls.
- Implementing or formatting dates, currency, and numbers.
- Applying compact visual sizing (fonts, paddings, icon dimensions).

---

## 1. Clean Code & Architectural Standards

- **Single Responsibility (SRP)**: Keep `build()` methods declarative and small. If a widget file exceeds ~250 lines, extract sections into dedicated private or shared widgets.
- **Separation of Concerns**: Never execute business logic, HTTP requests, or raw database queries inside UI widgets. UI only dispatches actions and renders state.
- **DRY (Don't Repeat Yourself)**: Avoid duplicating inline decorations, border styles, or modal configurations across multiple views.
- **State & Callbacks**: Child widgets must remain dumb/stateless where possible. Pass pure callbacks (`VoidCallback`, `ValueChanged<T>`) instead of coupling children to parent controllers or global states.
- **Const Constructors**: Use `const` everywhere possible to avoid unnecessary widget rebuilds.

---

## 2. Reusable Core UI Components Catalog (`frontend/lib/widgets/`)

All recurring inputs, buttons, cards, badges and dialogs MUST live in and be consumed from `frontend/lib/widgets/`:

| Componente | Tipo | Descripción |
| :--- | :--- | :--- |
| **`AppScreenWrapper`** | Layout | Contenedor obligatorio con doble modo (Desktop $\ge 850\text{px}$ / Mobile $< 850\text{px}$). |
| **`AppButton`** | Acción | Botón universal con `isLoading` integrado (alturas 36px, 42px o 50px). Nunca aplastado. |
| **`AppTextField`** | Entrada | Campo de texto limpio, soporte Dark/Light, toggle de contraseña y validación. |
| **`AppDropdown<T>`** | Entrada | Desplegable tipado con altura cómoda (38px), label opcional y bordes redondeados. |
| **`AppDatePickerField`** | Entrada | Selector de fecha estandarizado con formato `dd/MM/yyyy` y calendario corporativo. |
| **`AppAlert`** | Feedback | Banners en formulario y SnackBar flotante con `AppAlert.showToast(...)`. |
| **`AppConfirmDialog`** | Diálogo | Modal de confirmación para eliminar o aprobar acciones con `AppConfirmDialog.show(...)`. |
| **`AppCard`** | Salida | Tarjeta blanca uniforme con sombra sutil y cabecera opcional. |
| **`AppDataTable`** | Salida | Tabla de datos corporativa basada en `mecael` (`Table` nativo, `FlexColumnWidth`, filas cebra y fila `TOTAL`). |
| **`AppPaginator`** | Salida | Barra de paginación completa con selector de filas, contador "Mostrando X - Y de Z", botones de inicio/fin y burbuja de página. |
| **`AppStatusBadge`** | Salida | Chips de estado ultra-compactos (Activo, Inactivo, Pendiente, Facturado). |
| **`AppStatCard`** | Salida | Tarjetas de métrica y KPI para dashboards y balances de obra. |
| **`AppEmptyState`** | Salida | Vista amigable para listas y tablas vacías. |

Consulte la regla [.agents/rules/global-ui-components.md](file:///c:/Users/luism/OneDrive/Escritorio/ludeveloper/construcion/.agents/rules/global-ui-components.md) para ejemplos detallados de implementación.
