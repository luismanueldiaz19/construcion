---
name: laravel-module-pattern
description: >-
  Use this skill whenever the user asks to create a NEW backend module in this
  Laravel project (Industria California). It enforces the canonical module
  structure located at backend/app/Modules/, mirrors the Vehiculo module
  pattern, and covers: Enums, Models, Services, Http/Controllers,
  Http/Requests, and Providers, plus route registration and provider
  bootstrapping without BOM in UTF-8 files.
---

# Laravel Module Pattern — Industria California

## When to activate this skill

Activate this skill whenever the user says phrases like:
- "crea el modulo de X"
- "haz el backend de X"
- "nuevo modulo backend"
- "implementa el CRUD de X"

---

## 1. Canonical Folder Structure

Every module lives at `backend/app/Modules/{ModuleName}/` and follows this layout:

```
{ModuleName}/
├── Enums/
│   └── {EstadoX}.php            <- one enum per relevant state / type
├── Models/
│   └── {ModelName}.php          <- Eloquent models (module namespace, NOT App\Models)
├── Http/
│   ├── Controllers/
│   │   └── {ModelName}Controller.php
│   └── Requests/
│       ├── Store{ModelName}Request.php
│       └── Update{ModelName}Request.php
├── Services/
│   └── {ModelName}Service.php   <- ALL business logic lives here
└── Providers/
    └── {ModuleName}ServiceProvider.php
```

> **IMPORTANT**: Do NOT place new module models in `app/Models/`. They belong in
> `app/Modules/{ModuleName}/Models/`.
> Existing legacy models in `app/Models/` are kept only for backward compatibility.

---

## 2. Enums

Use PHP 8.1 backed string enums. One file per concept.

```php
<?php
namespace App\Modules\{ModuleName}\Enums;

enum EstadoX: string
{
    case Activo   = 'activo';
    case Inactivo = 'inactivo';
}
```

Rules:
- The enum value must match the exact string stored in the database `enum` column.
- Cast enums in the model using `$casts`.
- Never use raw strings in service logic; always reference enum cases.

---

## 3. Models

```php
<?php
namespace App\Modules\{ModuleName}\Models;

use App\Models\User;
use App\Modules\{ModuleName}\Enums\EstadoX;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class {ModelName} extends Model
{
    protected $table = '{table_name}';   // snake_case plural

    protected $fillable = [
        'campo_uno',
        'campo_dos',
        'estado',
        'created_by',
    ];

    protected $casts = [
        'estado'      => EstadoX::class,
        'monto_total' => 'decimal:2',
        'fecha'       => 'datetime',
    ];

    // Column name workaround for non-ASCII column names (e.g. "ano")
    // If a migration column uses a UTF-8 character like "anno", map it
    // to an ASCII accessor so fillable works cleanly:
    //
    // public function getAnioAttribute(): ?int  { return $this->attributes['anno'] ?? null; }
    // public function setAnioAttribute(?int $v): void { $this->attributes['anno'] = $v; }

    // Relations

    public function creador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Add hasMany / belongsTo / belongsToMany as needed

    // Helpers

    public function estaActivo(): bool
    {
        return $this->estado === EstadoX::Activo;
    }
}
```

---

## 4. Service (business logic)

The service is the ONLY place where business rules live.
The controller delegates everything non-trivial to the service.

```php
<?php
namespace App\Modules\{ModuleName}\Services;

use App\Models\User;
use App\Modules\{ModuleName}\Enums\EstadoX;
use App\Modules\{ModuleName}\Models\{ModelName};
use Illuminate\Support\Facades\DB;

class {ModelName}Service
{
    public function crear(array $datos, User $responsable): {ModelName}
    {
        $datos['created_by'] = $responsable->id;
        return {ModelName}::create($datos);
    }

    public function actualizar({ModelName} $model, array $datos): {ModelName}
    {
        if (isset($datos['estado'])) {
            $nuevo = EstadoX::from($datos['estado']);
            // add guard clauses here (state-machine transitions)
            $datos['estado'] = $nuevo;
        }
        $model->update($datos);
        return $model->fresh();
    }

    public function eliminar({ModelName} $model): void
    {
        // if ($model->subRecords()->count() > 0) {
        //     throw new \Exception('No se puede eliminar. Tiene registros asociados.');
        // }
        $model->delete();
    }

    public function resumen(): array
    {
        return [
            'total' => {ModelName}::count(),
        ];
    }
}
```

Service rules:
- Wrap multi-step mutations in DB::transaction(fn() => ...).
- Throw \Exception with a human-readable Spanish message for business violations.
- The controller catches \Exception and returns 422 with ['message' => $e->getMessage()].
- Never put DB:: queries in controllers or models.

---

## 5. Controller

```php
<?php
namespace App\Modules\{ModuleName}\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\{ModuleName}\Http\Requests\Store{ModelName}Request;
use App\Modules\{ModuleName}\Http\Requests\Update{ModelName}Request;
use App\Modules\{ModuleName}\Models\{ModelName};
use App\Modules\{ModuleName}\Services\{ModelName}Service;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class {ModelName}Controller extends Controller
{
    public function __construct(
        private readonly {ModelName}Service $service
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = {ModelName}::query()->with('creador:id,name');
        // Add optional filters from $request here
        return response()->json($query->orderBy('id')->get());
    }

    public function store(Store{ModelName}Request $request): JsonResponse
    {
        try {
            $record = $this->service->crear($request->validated(), Auth::user());
            return response()->json($record, 201);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function show({ModelName} ${modelVar}): JsonResponse
    {
        return response()->json(${modelVar}->load(['creador:id,name']));
    }

    public function update(Update{ModelName}Request $request, {ModelName} ${modelVar}): JsonResponse
    {
        try {
            $record = $this->service->actualizar(${modelVar}, $request->validated());
            return response()->json($record, 200);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }

    public function destroy({ModelName} ${modelVar}): JsonResponse
    {
        try {
            $this->service->eliminar(${modelVar});
            return response()->json(null, 204);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }
    }
}
```

Controller rules:
- Controllers are thin, no business logic.
- Every method returns JsonResponse.
- Use typed constructor injection for the service (private readonly).
- Extra non-CRUD actions (sub-resources, bulk operations) go as extra methods
  and are registered as explicit routes BEFORE Route::apiResource(...).

---

## 6. Form Requests

```php
<?php
namespace App\Modules\{ModuleName}\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class Store{ModelName}Request extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'campo_requerido' => 'required|string|max:255',
            'estado'          => 'nullable|in:activo,inactivo',
        ];
    }

    public function messages(): array
    {
        return [
            'campo_requerido.required' => 'El campo es obligatorio.',
        ];
    }
}
```

For Update{ModelName}Request, use nullable on most fields and include the
unique ignore rule for the current record ID:

```php
$id = $this->route('{modelVar}')?->id;
'ficha' => "nullable|string|max:20|unique:tabla,ficha,{$id}",
```

---

## 7. Service Provider

```php
<?php
namespace App\Modules\{ModuleName}\Providers;

use Illuminate\Support\ServiceProvider;

class {ModuleName}ServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Add repository bindings here if needed in the future
    }

    public function boot(): void
    {
        // Register policies: Gate::policy(ModelName::class, ModelNamePolicy::class);
    }
}
```

---

## 8. Registration Checklist

After creating all files you MUST complete BOTH steps:

### Step A: Register the provider in `backend/bootstrap/providers.php`

```php
return [
    // ... existing providers ...
    App\Modules\{ModuleName}\Providers\{ModuleName}ServiceProvider::class,
];
```

### Step B: Add routes to `backend/routes/api.php`

Place routes INSIDE the authenticated industria-california group.
Register explicit sub-resource routes BEFORE Route::apiResource() to avoid
Laravel resolving them as {model} wildcard parameters.

```php
use App\Modules\{ModuleName}\Http\Controllers\{ModelName}Controller;

// Inside the auth group:
// --- MODULO {MODULENAME} ---
Route::get('{recursos}/resumen', [{ModelName}Controller::class, 'resumen']);
// Sub-resources (if any):
Route::get('{recursos}/{model}/sub',  [{ModelName}Controller::class, 'subIndex']);
Route::post('{recursos}/{model}/sub', [{ModelName}Controller::class, 'subStore']);
// Base CRUD always last:
Route::apiResource('{recursos}', {ModelName}Controller::class);
```

---

## 9. File Encoding — CRITICAL

All PHP files MUST be UTF-8 WITHOUT BOM.

PowerShell's Set-Content -Encoding UTF8 adds a BOM that breaks Laravel's
namespace parser. Always write files using:

```powershell
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($absolutePath, $content, $utf8NoBom)
```

Or batch-fix after writing all files:

```powershell
$files = Get-ChildItem -Path "app\Modules\{ModuleName}" -Recurse -Filter "*.php"
foreach ($f in $files) {
    $c = Get-Content $f.FullName -Raw -Encoding UTF8
    [System.IO.File]::WriteAllText($f.FullName, $c, [System.Text.UTF8Encoding]::new($false))
}
```

---

## 10. Validation Commands

Run these after creating the module to confirm everything works:

```powershell
# Verify routes are registered (replace "recursos" with actual slug)
php artisan route:list --path=recursos

# Test the service resolves and DB queries work
php artisan tinker --execute="echo json_encode((new App\Modules\{ModuleName}\Services\{ModelName}Service)->resumen());"

# Clear all caches
php artisan optimize:clear
```

---

## 11. Reference Module — Vehiculo

The Vehiculo module (created 2026-09-25) is the canonical reference implementation.
Study its files when in doubt:

- 4 Enums: EstadoVehiculo, EstadoMantenimiento, TipoEnergia, TipoMantenimiento
- 3 Models: Vehiculo, VehiculoMantenimiento, VehiculoGasto
- 1 Controller: 14 methods (CRUD + sub-resources mantenimientos + gastos)
- 4 Form Requests: Store/Update Vehiculo, StoreMantenimiento, StoreGasto
- 1 Service: auto state transitions, monto_total calculation, resumenFlota()
- 1 ServiceProvider
- 28 routes at api/v1/industria-california/vehiculos