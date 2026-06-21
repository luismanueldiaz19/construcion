# Reglas Fundamentales de Ingeniería de Software

## Objetivo

Todo código generado, modificado o refactorizado por el Agente IA debe cumplir estas reglas sin excepción.

El objetivo principal es:

* Robustez
* Escalabilidad
* Seguridad
* Mantenibilidad
* Reutilización
* Bajo acoplamiento
* Alta cohesión
* Cero duplicidad
* Código limpio y legible

---

# 1. Principios Generales

## 1.1 No confiar en la entrada del usuario

Nunca asumir que los datos recibidos son correctos.

Siempre validar:

* Tipos de datos
* Longitud
* Formato
* Valores permitidos
* Nulos
* Rangos

Ejemplos:

* Email válido
* Fecha válida
* UUID válido
* ID existente
* Números positivos

Toda entrada debe considerarse potencialmente incorrecta o maliciosa.

---

## 1.2 Fail Fast

Detectar errores lo antes posible.

No permitir que errores viajen por múltiples capas del sistema.

Validar en:

* Frontend
* Backend
* Base de datos

---

## 1.3 Programar para el cambio

Todo módulo debe diseñarse pensando que cambiará en el futuro.

Evitar:

* Valores hardcodeados
* Dependencias rígidas
* Código específico de un solo caso

---

# 2. Clean Code

## Obligatorio

### Nombres claros

Incorrecto:

```php
$x
$data
$temp
```

Correcto:

```php
$customerName
$totalAmount
$invoiceDate
```

---

### Funciones pequeñas

Una función debe realizar una sola responsabilidad.

Ideal:

```php
10 a 30 líneas
```

Máximo recomendado:

```php
50 líneas
```

---

### Evitar comentarios innecesarios

El código debe explicarse por sí mismo.

Mal:

```php
// Sumar dos números
$total = $a + $b;
```

Bien:

```php
$totalInvoiceAmount = $subtotal + $tax;
```

---

# 3. Principios SOLID

## S - Single Responsibility

Una clase debe tener una única responsabilidad.

---

## O - Open/Closed

Abierta para extensión.

Cerrada para modificación.

Usar:

* Interfaces
* Abstracciones
* Estrategias

---

## L - Liskov Substitution

Las implementaciones deben poder reemplazar a sus abstracciones sin romper comportamiento.

---

## I - Interface Segregation

Interfaces pequeñas y específicas.

Evitar interfaces gigantes.

---

## D - Dependency Inversion

Depender de abstracciones.

Nunca de implementaciones concretas.

---

# 4. Arquitectura

## Backend Laravel

Usar arquitectura por módulos.

```text
app/
└── Modules/
    ├── Clients/
    ├── Projects/
    ├── Loans/
    ├── Inventory/
    └── Accounting/
```

Cada módulo debe contener:

```text
Module/
├── Controllers/
├── Services/
├── Repositories/
├── Models/
├── DTOs/
├── Requests/
├── Policies/
├── Resources/
└── Tests/
```

---

## Flujo obligatorio

```text
Controller
    ↓
Service
    ↓
Repository
    ↓
Database
```

Nunca:

```text
Controller → Database
```

---

# 5. Repository Pattern

Toda consulta compleja debe utilizar Repository.

Ejemplo:

```php
CustomerRepository
ProjectRepository
InvoiceRepository
```

Beneficios:

* Reutilización
* Testabilidad
* Menor acoplamiento

---

# 6. Service Layer

Toda lógica de negocio debe estar en Services.

Nunca colocar lógica de negocio en:

* Controllers
* Widgets
* Views
* Models

---

# 7. DTO Pattern

Usar DTO para transportar información.

Evitar:

```php
$request->all()
```

Preferir:

```php
CreateCustomerDTO
UpdateProjectDTO
```

---

# 8. Validaciones

Toda operación debe validar:

## Backend

Laravel Form Request

```php
StoreCustomerRequest
UpdateProjectRequest
```

---

## Frontend Flutter

Validar antes de llamar API.

Ejemplos:

* Campos requeridos
* Formatos
* Rangos
* Longitudes

---

# 9. Manejo de Errores

Nunca:

```php
try {
} catch(Exception $e) {
}
```

sin registrar errores.

Siempre:

```php
Log::error(...)
```

---

Responder errores estandarizados:

```json
{
  "success": false,
  "message": "Customer not found",
  "errors": []
}
```

---

# 10. Base de Datos

## Reglas

* Normalización adecuada
* Índices correctos
* Claves foráneas
* Restricciones

Siempre utilizar:

```sql
NOT NULL
UNIQUE
FOREIGN KEY
CHECK
```

cuando aplique.

---

# 11. Seguridad

## Obligatorio

### Laravel

* Policies
* Gates
* Middleware
* CSRF
* Rate Limiting

---

Nunca exponer:

* Passwords
* Tokens
* Secret Keys
* Connection Strings

---

# 12. DRY

Don't Repeat Yourself.

Si un bloque aparece más de dos veces:

Refactorizar.

Crear:

* Componente
* Servicio
* Helper
* Trait

---

# 13. KISS

Keep It Simple.

Siempre elegir la solución más simple que cumpla el requisito.

No sobreingeniería.

---

# 14. YAGNI

You Aren't Gonna Need It.

No implementar funcionalidades futuras no solicitadas.

---

# 15. Flutter Architecture

Arquitectura recomendada:

```text
lib/
└── modules/
    ├── clients/
    ├── projects/
    ├── inventory/
    └── accounting/
```

Cada módulo:

```text
module/
├── screens/
├── widgets/
├── providers/
├── services/
├── repositories/
├── models/
├── dto/
└── validators/
```

---

# 16. Componentes Flutter

Todo componente debe:

* Ser reutilizable
* Ser configurable
* Tener responsabilidad única

Evitar widgets gigantes.

Si un widget supera:

```text
200 líneas
```

Evaluar dividirlo.

---

# 17. Responsive Design

Obligatorio soportar:

* Web
* Tablet
* Mobile
* Windows Desktop

---

Nunca usar:

```dart
width: 400
height: 700
```

fijos sin justificación.

Usar:

```dart
LayoutBuilder
MediaQuery
Responsive Breakpoints
```

---

# 18. Testing

Cobertura mínima:

```text
80%
```

Tipos:

* Unit Test
* Widget Test
* Integration Test
* API Test

---

# 19. Rendimiento

Evitar:

* Consultas N+1
* Widgets innecesarios
* Rebuilds excesivos
* Cargas completas de tablas

Usar:

* Pagination
* Lazy Loading
* Caching
* Eager Loading

---

# 20. Escalabilidad

Toda solución debe soportar:

* Miles de usuarios
* Millones de registros
* Múltiples módulos

Evitar diseños que obliguen a reescribir el sistema completo en el futuro.

---

# 21. Regla Suprema

Antes de generar código, el Agente IA debe preguntarse:

1. ¿Es seguro?
2. ¿Es mantenible?
3. ¿Es reutilizable?
4. ¿Es escalable?
5. ¿Evita duplicidad?
6. ¿Respeta SOLID?
7. ¿Respeta Clean Code?
8. ¿Es testeable?
9. ¿Es responsive?
10. ¿Existe una solución más simple?

Si alguna respuesta es NO, la implementación debe ser rechazada y rediseñada.
