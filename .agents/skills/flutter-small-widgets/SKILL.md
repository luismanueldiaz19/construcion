---
name: flutter-small-widgets
description: >-
  Use this skill when the user asks to create, modify, or refactor Flutter Widgets
  in this project, enforcing an ultra-compact UI design (minimal fonts, tight paddings,
  small icons) while strictly preserving comfortable, uncrushed Buttons and TextFields.
---

# Creating Ultra-Compact Flutter Widgets (Small & Dense UI)

Prioritize an ultra-compact, high-density UI across this project while strictly preventing cramped or crushed input controls. Follow these guidelines:

## 1. Ultra-Compact Typography
- **Screen & Module Titles**: `16px` to `18px` (`FontWeight.bold`).
- **Section Headers & Subtitles**: `13px` to `14px`.
- **Body, Table Cells & Form Labels**: `11px` to `12px`.
- **Badges, Chips, Timestamps & Micro-text**: `10px` to `11px`.

## 2. Tight Spacing & Margins
- **Gaps & Dividers**: Prefer `4px`, `6px` or `8px` for `SizedBox`.
- **Container / Card Padding**: `6.0` to `8.0` (maximum `10.0`).
- **Icon Sizes**: `14px` to `16px` (max `18px` in toolbars).
- **Density**: Use `VisualDensity.compact` or `VisualDensity(horizontal: -3, vertical: -3)` in DataTables and ListTiles.

## 3. REGLA OBLIGATORIA: NO Aplastar Botones ni Campos de Texto

### A. Botones de Acción
- **NUNCA** uses `minimumSize: Size.zero` junto con `tapTargetSize: MaterialTapTargetSize.shrinkWrap` en botones de acción (`ElevatedButton`, `OutlinedButton`, `FilledButton`, `AppButton`), ya que los deja aplastados e inutilizables.
- Los botones de acción deben mantener una **altura mínima cómoda de `34px` a `38px`** (ej. `minimumSize: const Size(0, 36)` o `height: 36` con `padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)`).

### B. Campos de Texto e Inputs (TextField, TextFormField, AppTextField)
- **NUNCA** uses alturas menores a `36px` ni `contentPadding: EdgeInsets.zero`. Los inputs colapsados cortan las letras descendentes (como `g`, `j`, `p`, `y`) y lucen deformes.
- Los campos de texto deben mantener una **altura cómoda de `36px` a `40px`**, con `isDense: true` y `contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8 a 10)`.
- El texto del input debe mantenerse entre `12px` y `13px` para asegurar total legibilidad.

### C. Diálogos y Modales
- Mantener un respiro interno cómodo (`padding: 16–20px`) y una separación de al menos `10–12px` entre campos y botones para que la vista compacta no pierda claridad ni elegancia.
