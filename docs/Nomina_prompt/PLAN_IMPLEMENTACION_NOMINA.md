# Módulo de Empleados y Nómina — Plan de Implementación
**Fecha:** 2026-07-15  
**Stack:** Laravel API (backend) + Flutter (frontend)  
**Legislación:** República Dominicana (Código de Trabajo, Ley 87-01, Código Tributario)

---

## Contexto

El proyecto ya tiene un backend Laravel con módulos de proyectos, compras, contabilidad (catalogo_cuentas, asientos_contables), activos y clientes. Vamos a agregar el **Módulo de Empleados y Nómina** completo según el PROMPT MAESTRO, siguiendo exactamente la misma estructura del proyecto existente: **sin tocar nada de lo que ya está hecho**.

La arquitectura sigue el patrón: **Migraciones → Modelos → Seeders → Services → Controllers → Routes**. Cada proceso/tarea genera su propio **archivo `.txt` de log** en `docs/Nomina_prompt/logs/` para mantener contexto.

---

## Entidad-Relación (Tablas Nuevas)

```
departments ──────────────────────────────────────────────┐
positions (FK → departments) ────────────────────────────┤
work_schedules ───────────────────────────────────────────┤
payroll_groups ───────────────────────────────────────────┤
afps (Administradoras de Fondos de Pensiones) ────────────┤
arss (Administradoras de Riesgos de Salud) ───────────────┤
banks ────────────────────────────────────────────────────┤
                                                          │
employees (FK → todos los anteriores + self-ref supervisor_id)
    ├── employee_dependents (FK → employees)
    ├── employee_documents (FK → employees)
    ├── employee_salary_history (FK → employees)
    ├── employee_status_history (FK → employees)
    └── employee_bank_accounts (FK → employees)

payroll_legal_parameters (tabla versionada de porcentajes legales)
payroll_concepts (FK → catalogo_cuentas)
payroll_periods (FK → payroll_groups)
payrolls (FK → payroll_periods)
    ├── payroll_details (FK → payrolls, employees, payroll_concepts)
    └── payslips (FK → payrolls, employees)

payroll_loans (FK → employees)
```

---

## Orden de Ejecución — Tareas

### TAREA 1 — Migraciones de Tablas Base (sin FK hacia employees)
Crear en un solo archivo: `departments`, `positions`, `work_schedules`, `payroll_groups`, `afps`, `arss`, `banks`
- **Log:** `docs/Nomina_prompt/logs/tarea_01_migraciones_base.txt`

### TAREA 2 — Migración de `employees` y tablas hijas
Crear: `employees`, `employee_dependents`, `employee_documents`, `employee_salary_history`, `employee_status_history`, `employee_bank_accounts`
- **Log:** `docs/Nomina_prompt/logs/tarea_02_migraciones_employees.txt`

### TAREA 3 — Migraciones del Motor de Nómina
Crear: `payroll_legal_parameters`, `payroll_concepts`, `payroll_periods`, `payrolls`, `payroll_details`, `payroll_loans`, `payslips`
- **Log:** `docs/Nomina_prompt/logs/tarea_03_migraciones_nomina.txt`

### TAREA 4 — Modelos Eloquent (con relaciones)
Crear todos los modelos con sus relaciones, fillables, casts y soft deletes donde aplica.
- **Log:** `docs/Nomina_prompt/logs/tarea_04_modelos.txt`

### TAREA 5 — Seeders de Parámetros Legales y Conceptos de Nómina
Sembrar: AFPs, ARSs, Bancos, `payroll_legal_parameters` (TSS, ISR 2026 RD), `payroll_concepts` mínimos (salario base, TSS empleado/patronal, ISR, horas extras, etc.)
- **Log:** `docs/Nomina_prompt/logs/tarea_05_seeders.txt`

### TAREA 6 — PayrollCalculationService
El motor de cálculo desacoplado: salario prorrateado → TSS → ISR anualizado → deducciones → aportes patronales → provisiones.
- **Log:** `docs/Nomina_prompt/logs/tarea_06_payroll_service.txt`

### TAREA 7 — Form Requests y Controladores
Controllers: `EmployeeController`, `DepartmentController`, `PositionController`, `PayrollGroupController`, `WorkScheduleController`, `PayrollController`, `PayrollConceptController`, `PayrollLoanController`
- **Log:** `docs/Nomina_prompt/logs/tarea_07_controllers.txt`

### TAREA 8 — Rutas API
Agregar todas las rutas de nómina en `api.php` sin romper las existentes.
- **Log:** `docs/Nomina_prompt/logs/tarea_08_rutas.txt`

### TAREA 9 — Exportación Excel (Maatwebsite Excel) ⭐ NUEVO
Exportadores para uso del contador/RRHH:
- Nómina consolidada por periodo (Excel)
- Planilla TSS (formato exigible)
- Histórico de salarios por empleado
- Reporte de retenciones ISR
- Reporte de provisiones acumuladas (regalía, vacaciones, cesantía)
- Libro de nómina / Kardex del empleado
- **Librería:** `maatwebsite/excel` (ya referenciada en el prompt maestro)
- **Log:** `docs/Nomina_prompt/logs/tarea_09_excel_exports.txt`

---

## Notas importantes

- Los porcentajes legales (TSS, ISR 2026 RD) se cargarán como valores de ejemplo. **Validar con valores oficiales antes de producción.**
- El ISR siempre se calcula sobre base anualizada (annualizar → calcular impuesto anual → prorratear al periodo).
- Una nómina cerrada es **inmutable**. Solo se corrige vía asiento de ajuste en el periodo siguiente.
- Nunca eliminar físicamente un empleado con nómina procesada — solo soft delete + estado `desvinculado`.

---

## Verificación

- `php artisan migrate` — sin errores
- `php artisan db:seed --class=NominaSeeder`
- Endpoints probados con Postman
- Exportaciones Excel generadas correctamente

---

## Evidencia de Ejecución

| Tarea | Archivo de Log | Estado |
|-------|---------------|--------|
| 01 — Migraciones base | `logs/tarea_01_migraciones_base.txt` | ✅ 2026-07-15 |
| 02 — Migración employees | `logs/tarea_02_migraciones_employees.txt` | ✅ 2026-07-15 |
| 03 — Migraciones nómina | `logs/tarea_03_migraciones_nomina.txt` | ✅ 2026-07-15 |
| 04 — Modelos Eloquent | `logs/tarea_04_modelos.txt` | ✅ 2026-07-15 |
| 05 — Seeders | `logs/tarea_05_seeders.txt` | ✅ 2026-07-15 |
| 06 — PayrollCalculationService | `logs/tarea_06_payroll_service.txt` | ✅ 2026-07-15 |
| 07 — Controllers | `logs/tarea_07_controllers.txt` | ✅ 2026-07-15 |
| 08 — Rutas API | `logs/tarea_08_rutas.txt` | ✅ 2026-07-15 |
| 09 — Exportación Excel | `logs/tarea_09_excel_exports.txt` | ✅ 2026-07-15 |

**Ejecución completada: 2026-07-15. Backend del módulo de nómina 100% implementado.**
