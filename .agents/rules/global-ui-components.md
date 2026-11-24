# Guía Mandatoria: Componentes Globales de UI (Frontend)

Para cualquier agente o desarrollador que cree, modifique o refactorice pantallas en este proyecto, **es obligatorio utilizar los componentes globales estandarizados ubicados en `frontend/lib/widgets/`**.

> **REGLA DE ORO**: NUNCA inventes estilos inline de `InputDecoration`, bordes manuales, botones con `minimumSize: Size.zero`, ni diálogos ad-hoc. Toda la interfaz debe componerse con esta librería global.

---

## 1. Catálogo de Componentes Estandarizados

### A. Estructura & Doble Pantalla
| Componente | Archivo | Cuándo Usarlo |
| :--- | :--- | :--- |
| **`AppScreenWrapper`** | `widgets/app_screen_wrapper.dart` | **Envoltorio obligatorio** de todas las pantallas del ERP. Soporta los 2 modos (Escritorio $\ge 850\text{px}$ y Móvil $< 850\text{px}$), encabezado con título/subtítulo, barra de filtros y estados `isLoading` y `errorMessage`. |

---

### B. Componentes de Entrada (Inputs)
| Componente | Archivo | Cuándo Usarlo |
| :--- | :--- | :--- |
| **`AppTextField`** | `widgets/app_text_field.dart` | Campos de texto estándar, búsqueda o contraseñas (`isPassword: true`). Soporta `isDark: true` para fondos oscuros o `false` para tarjetas blancas. Altura mínima de 38–40px (nunca aplastado). |
| **`AppDropdown<T>`** | `widgets/app_dropdown.dart` | Selectores y desplegables tipados con etiqueta superior opcional, altura cómoda (38px) y bordes redondeados (10px). |
| **`AppDatePickerField`** | `widgets/app_date_picker_field.dart` | Selección de fechas con formato centralizado `dd/MM/yyyy`, calendario corporativo y opción de limpieza. |

---

### C. Acciones, Notificaciones y Diálogos
| Componente | Archivo | Cuándo Usarlo |
| :--- | :--- | :--- |
| **`AppButton`** | `widgets/app_button.dart` | **Todos los botones de acción**. Incluye `isLoading` integrado (spinner dentro del botón). Variantes: `primary` (rojo `#E31E24`), `secondary`, `outlined`, `danger`, `success`. Tamaños: `compact` (36px), `standard` (42px) y `large` (50px). **NUNCA aplastar**. |
| **`AppAlert`** | `widgets/app_alert.dart` | Banners de aviso en formularios o notificaciones flotantes con `AppAlert.showToast(context, 'Mensaje...', type: ...)`. Tipos: `error`, `success`, `warning`, `info`. |
| **`AppConfirmDialog`** | `widgets/app_confirm_dialog.dart` | Modales de confirmación para eliminar o ejecutar acciones críticas con `await AppConfirmDialog.show(context, title: ..., message: ...)`. |

---

### D. Componentes de Salida (Data Display)
| Componente | Archivo | Cuándo Usarlo |
| :--- | :--- | :--- |
| **`AppCard`** | `widgets/app_card.dart` | Contenedor base uniforme para secciones, formularios y resúmenes con sombra suave y cabecera opcional. |
| **`AppDataTable`** | `widgets/app_data_table.dart` | **Tabla corporativa estandarizada**: Basada en la arquitectura de `mecael` (`Table` nativo, `FlexColumnWidth`, filas cebra, celdas compactas, fila inferior `TOTAL` y scrollbar visible). |
| **`AppPaginator`** | `widgets/app_paginator.dart` | **Paginador ergonómico**: Selector de filas por página, contador descriptivo ("Mostrando X - Y de Z"), botones de primera/última página y burbuja indicadora de página activa. |
| **`AppStatusBadge`** | `widgets/app_status_badge.dart` | Chips de estado ultra-compactos (10–11px) para tablas y listas (Activo, Inactivo, Pendiente, Facturado). |
| **`AppStatCard`** | `widgets/app_stat_card.dart` | Tarjetas de métricas y KPI para cabeceras de módulos (Total, Activos, Monto RD$). |
| **`AppEmptyState`** | `widgets/app_empty_state.dart` | Vista mostrada cuando un listado o catálogo no arroja resultados, con botón de acción opcional. |

---

## 2. Ejemplos de Implementación Rápida

### Ejemplo 1: Pantalla Completa con Doble Modo
```dart
import 'package:flutter/material.dart';
import '../../../../widgets/app_screen_wrapper.dart';
import '../../../../widgets/app_button.dart';

class MiModuloScreen extends StatelessWidget {
  const MiModuloScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenWrapper(
      title: 'Gestión de Contratos',
      subtitle: '12 contratos activos',
      actions: [
        AppButton(
          text: 'Nuevo Contrato',
          icon: Icons.add,
          size: AppButtonSize.compact,
          onPressed: () {},
        ),
      ],
      desktopView: const MiTablaDesktop(),
      mobileView: const MiListaMobileCards(),
    );
  }
}
```

### Ejemplo 2: Formulario con Inputs Globales
```dart
import '../../../../widgets/app_card.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/app_dropdown.dart';
import '../../../../widgets/app_date_picker_field.dart';
import '../../../../widgets/app_button.dart';

AppCard(
  title: 'Datos del Proveedor',
  child: Column(
    children: [
      AppTextField(
        labelText: 'Razón Social',
        hintText: 'Ingrese nombre comercial',
        controller: _nameController,
      ),
      const SizedBox(height: 12),
      AppDropdown<String>(
        labelText: 'Tipo de Empresa',
        value: _tipoSeleccionado,
        items: [...],
        onChanged: (val) => setState(() => _tipoSeleccionado = val),
      ),
      const SizedBox(height: 12),
      AppDatePickerField(
        labelText: 'Fecha de Registro',
        selectedDate: _fecha,
        onDateChanged: (val) => setState(() => _fecha = val),
      ),
      const SizedBox(height: 18),
      AppButton(
        text: 'Guardar Registro',
        isLoading: _isSaving,
        onPressed: _guardar,
      ),
    ],
  ),
)
```

---

## 3. Verificación de Cumplimiento de Skills
Antes de finalizar cualquier tarea en Flutter, el agente DEBE verificar:
1. No haber usado `InputDecoration` inline repetitivo.
2. No haber aplastado ningún botón (`minimumSize` siempre $\ge 34\text{px}$).
3. Haber ejecutado `flutter analyze` y asegurar **0 errores y 0 advertencias**.
