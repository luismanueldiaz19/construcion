# 🧩 Instrucciones para Agente IA — Pantalla "Nueva Compra de Materiales" (Flutter)

## 🎯 Objetivo
Crear una pantalla Flutter moderna y amigable para registrar compras de materiales, manteniendo los colores y patrones del diseño original (azul, blanco y acentos grises).  
La UI debe ser **modular, reutilizable, validada y con feedback visual**.

---

## 🏗️ Estructura General
La pantalla se divide en tres secciones principales:

1. **Encabezado y Detalles de Compra**
2. **Detalle de Materiales**
3. **Resumen y Registro**

Cada sección debe implementarse como un **Widget independiente** para favorecer la reutilización y pruebas unitarias.

---

## 📦 Arquitectura y Principios
- **Clean Architecture:** separar lógica de presentación, dominio y datos.
- **SOLID:** aplicar principios de responsabilidad única y dependencias invertidas.
- **State Management:** usar `ChangeNotifier` o `Riverpod` para manejar estado reactivo.
- **Validaciones:** cada campo debe tener validación visual y lógica (por ejemplo, proveedor no vacío, cantidad > 0).
- **Feedback visual:** usar `SnackBar`, `Dialog` o `AnimatedContainer` para mostrar éxito o error.

---

## 🧱 Componentes Principales

### 1️⃣ Encabezado y Detalles de Compra
**Widget:** `PurchaseHeaderSection`

Campos:
- Proveedor (Dropdown + buscador)
- Proyecto Destino (Dropdown)
- Tipo de Compra (Dropdown)
- Fecha de Compra (DatePicker)
- Orden #
- Código Ref.
- Comprobante
- Notas / Observaciones (TextArea)

**Recomendaciones:**
- Usar `Card` con bordes redondeados y sombra ligera.
- Agrupar campos en filas de 2 para pantallas grandes.
- Implementar `Form` con `GlobalKey<FormState>` para validaciones.

---

### 2️⃣ Detalle de Materiales
**Widget:** `MaterialDetailSection`

Campos:
- Material (Dropdown + buscador)
- Cantidad (TextField numérico)
- Precio Unitario (TextField numérico)
- ITBIS (18%) (calculado automáticamente)
- Importe Total (calculado automáticamente)

**Botón:** `Agregar Material`

**Recomendaciones:**
- Usar `DataTable` o `ListView.builder` para mostrar materiales agregados.
- Cada fila debe tener opción de editar o eliminar.
- Calcular totales dinámicamente al modificar cantidad o precio.

---

### 3️⃣ Resumen y Registro
**Widget:** `PurchaseSummarySection`

Campos:
- Sub-total
- ITBIS (18%)
- Total General

**Botón Principal:** `REGISTRAR COMPRA`

**Recomendaciones:**
- Mostrar totales en un `Container` con fondo azul claro y texto en negrita.
- Al presionar “Registrar Compra”, validar todos los campos y mostrar animación de éxito.

---

## 🎨 Estilo y Temas
- **Colores:** Azul (#004AAD), Blanco (#FFFFFF), Gris claro (#F5F5F5)
- **Tipografía:** Usar `Roboto` o `Poppins`
- **Botones:** Elevados con `RoundedRectangleBorder`
- **Iconografía:** Material Icons (`search`, `calendar_today`, `add_circle_outline`)

---

## 🧠 Lógica de Negocio
- Calcular ITBIS como `precio_unitario * cantidad * 0.18`
- Calcular total general como `sum(subtotal + itbis)`
- Validar que no se repita el mismo material en la lista.
- Mostrar advertencia si la cantidad supera el stock disponible.

---

## ⚙️ Ejemplo de Estructura de Código

```dart
class NuevaCompraPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva Compra de Materiales')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PurchaseHeaderSection(),
            MaterialDetailSection(),
            PurchaseSummarySection(),
          ],
        ),
      ),
    );
  }
}
