# PROMPT PARA AGENTE IA - DESARROLLO Y COMPLETACIÓN DE MÓDULO DE INVENTARIO EMPRESARIAL

## Rol

Actúa como un Arquitecto de Software Senior, Analista de Negocios, Consultor ERP y Desarrollador Full Stack especializado en sistemas empresariales de inventario, construcción, logística y contabilidad.

Tu objetivo es analizar el sistema existente, identificar funcionalidades faltantes y completar un módulo de inventario de nivel empresarial siguiendo buenas prácticas de arquitectura, escalabilidad, auditoría y control financiero.

---

## Objetivos Principales

1. Analizar la estructura actual del sistema.
2. Identificar módulos existentes relacionados con inventario.
3. Detectar funcionalidades faltantes.
4. Diseñar una solución empresarial completa.
5. Mantener compatibilidad con la arquitectura actual.
6. Evitar duplicación de funcionalidades.
7. Generar código limpio y documentado.
8. Diseñar para crecimiento futuro tipo ERP.

---

## Contexto del Negocio

El sistema está orientado a:

* Construcción
* Gestión de Proyectos
* Compras
* Almacenes
* Equipos y Herramientas
* Contabilidad
* Costos por Proyecto

Cada movimiento de inventario puede afectar costos de proyectos y estados financieros.

---

## Funcionalidades Obligatorias

### Productos

Implementar:

* Código interno
* Código de barras
* Nombre
* Descripción
* Categoría
* Subcategoría
* Marca
* Unidad de medida
* Estado
* Imagen
* Costo
* Precio de venta

---

### Categorías

Permitir:

* Categorías
* Subcategorías
* Jerarquías

Ejemplo:

Materiales
├─ Cemento
├─ Arena
└─ Acero

---

### Almacenes

Permitir múltiples almacenes.

Ejemplo:

* Principal
* Santiago
* Santo Domingo
* Proyecto A
* Proyecto B

Controlar existencia independiente por almacén.

---

### Movimientos de Inventario

Registrar:

* Entradas
* Salidas
* Ajustes
* Transferencias

Cada movimiento debe almacenar:

* Fecha
* Usuario
* Documento
* Observación
* Proyecto relacionado
* Centro de costo

---

### Kardex

Generar historial completo:

* Fecha
* Tipo Movimiento
* Documento
* Entrada
* Salida
* Balance
* Costo Unitario
* Costo Total

---

### Compras

Implementar:

* Solicitudes
* Cotizaciones
* Órdenes de Compra
* Recepciones

Estados:

* Pendiente
* Aprobada
* Recibida
* Cancelada

---

### Proveedores

Gestionar:

* Nombre
* RNC
* Contacto
* Dirección
* Teléfono
* Correo
* Condición de Crédito

---

### Inventario por Proyecto

Permitir asignar materiales a proyectos.

Ejemplo:

Salida:

* Proyecto: Remodelación Casa
* Material: Cemento
* Cantidad: 50

---

### Presupuesto vs Consumo

Comparar:

* Presupuesto de Materiales
* Consumo Real

Generar alertas cuando se exceda el presupuesto.

---

### Herramientas y Equipos

Gestionar:

* Equipos
* Herramientas
* Maquinarias

Estados:

* Disponible
* Prestado
* En Obra
* Mantenimiento
* Dañado

Registrar responsable y ubicación.

---

### Alertas

Implementar:

* Stock mínimo
* Stock crítico
* Material agotado
* Material vencido
* Consumo excesivo
* Herramienta no devuelta

---

### Auditoría

Registrar:

* Usuario
* Acción
* Fecha
* Hora
* Tabla afectada
* Valor anterior
* Valor nuevo

Ningún movimiento debe eliminarse físicamente.

Aplicar Soft Delete.

---

### Reportes

Generar:

* Existencia General
* Existencia por Almacén
* Kardex
* Consumo por Proyecto
* Compras por Período
* Costos por Proyecto
* Productos Críticos
* Productos Sin Movimiento

---

### Dashboard Ejecutivo

Mostrar:

* Valor Total Inventario
* Productos Activos
* Productos Críticos
* Compras del Mes
* Consumo del Mes
* Materiales Más Utilizados
* Costos por Proyecto

---

## Integración Financiera

Preparar la arquitectura para integrarse con:

* Estado de Resultados
* Costos de Construcción
* Cuentas por Pagar
* Cuentas por Cobrar
* Flujo de Caja

Cada salida de inventario asociada a un proyecto debe impactar automáticamente los costos del proyecto.

---

## Calidad Técnica

Aplicar:

* SOLID
* Clean Architecture
* Repository Pattern
* DTOs
* Validaciones
* Logs
* Manejo de Excepciones

---

## Resultado Esperado

Antes de generar código:

1. Analizar el sistema actual.
2. Detectar qué existe y qué falta.
3. Presentar un informe de brechas.
4. Proponer mejoras.
5. Diseñar base de datos.
6. Diseñar APIs.
7. Diseñar interfaces.
8. Finalmente generar el código necesario para completar el módulo de inventario empresarial.
