# Plan de Implementación: Obligaciones Fiscales y Pagos

Para que el sistema sepa qué retenciones e impuestos se deben pagar (ITBIS, TSS, ISR) y permita registrar su pago (con posibles moras/recargos), propongo el siguiente flujo de desarrollo.

## Propuesta de Cambios

### 1. Actualización del Catálogo de Cuentas (Backend)
- Añadir las cuentas por pagar de TSS e ISR (Ej. `2.1.04 TSS POR PAGAR`, `2.1.05 ISR POR PAGAR`) en el `CatalogoCuentasSeeder.php`. 
- Añadir la cuenta de Gasto por Recargos (Ej. `6.1.05 Recargos y Moras`).
- Ejecutaremos un comando para insertar estas cuentas sin borrar tu base de datos actual.

### 2. Backend API: Módulo de Obligaciones
- Modificaremos el `ContabilidadController.php` (o crearemos un `ObligacionesController`) para agregar:
  - `GET /api/v1/contabilidad/obligaciones`: Buscará el saldo actual (Haber - Debe) de las cuentas 2.1.03 (ITBIS), 2.1.04 (TSS), y 2.1.05 (ISR). Retornará un listado de las obligaciones pendientes.
  - `POST /api/v1/contabilidad/obligaciones/pagar`: Recibirá el código de la cuenta a pagar (ej. ITBIS), el monto a pagar, cuenta de banco de origen y monto de recargos (si aplica). Esto creará un **Asiento Contable** disminuyendo la deuda (Pasivo), registrando el gasto extra (si hay mora), y disminuyendo el balance del Banco (Activo).

### 3. Frontend: Interfaz de Usuario
- **Sidebar**: En la barra lateral (`app_sidebar.dart`), dentro de la sección "Contabilidad" o "Finanzas", agregaremos un botón llamado **"Obligaciones de Pago"** o "Impuestos".
- **Pantalla de Obligaciones**: Una nueva pantalla donde se listarán las 3 principales deudas (ITBIS, TSS, ISR) con su balance actual.
- **Ventana de Pago (Dialog)**: Al hacer clic en "Pagar" en cualquiera de las obligaciones, se abrirá un formulario donde podrás:
  1. Ver el monto adeudado.
  2. Seleccionar el banco desde donde pagas.
  3. Añadir el monto de los recargos o intereses (ej. el 10%, 4%, etc.).
  4. Pagar, lo que actualizará tus saldos contables en tiempo real.
