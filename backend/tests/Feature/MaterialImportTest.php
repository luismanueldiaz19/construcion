<?php

namespace Tests\Feature;

use App\Models\Material;
use App\Models\Categoria;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class MaterialImportTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_download_template()
    {
        $response = $this->get('/api/v1/materiales/import-template');
        $response->assertStatus(200);
        $response->assertHeader('Content-Disposition', 'attachment; filename="plantilla_productos.csv"');
        ob_start();
        $response->sendContent();
        $content = ob_get_clean();

        $this->assertStringContainsString('Codigo', $content);
        $this->assertStringContainsString('Nombre', $content);
    }

    public function test_can_import_valid_csv()
    {
        $csvContent = "Codigo,Nombre,Descripcion,Categoria,Unidad,Precio Costo\n"
            . "SKU-TEST-001,Material Test 1,Descripcion de prueba,Herramientas,UND,150.50\n"
            . "SKU-TEST-002,Material Test 2,,Pinturas,GL,890.00\n"
            . ",Material Test 3,Material sin codigo,Herramientas,M,12.00\n";

        $file = UploadedFile::fake()->createWithContent('productos.csv', $csvContent);

        $response = $this->postJson('/api/v1/materiales/import', [
            'file' => $file
        ]);

        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
            'inserted' => 3,
            'updated' => 0
        ]);

        // Verificar base de datos
        $this->assertDatabaseHas('materiales', [
            'codigo' => 'SKU-TEST-001',
            'nombre' => 'Material Test 1',
            'unidad' => 'UND',
            'precio_costo' => 150.50
        ]);

        $this->assertDatabaseHas('materiales', [
            'codigo' => 'SKU-TEST-002',
            'nombre' => 'Material Test 2',
            'unidad' => 'GL',
            'precio_costo' => 890.00
        ]);

        $this->assertDatabaseHas('materiales', [
            'codigo' => null,
            'nombre' => 'Material Test 3',
            'unidad' => 'M',
            'precio_costo' => 12.00
        ]);

        // Verificar que las categorías se crearon
        $this->assertDatabaseHas('categorias', ['nombre' => 'Herramientas']);
        $this->assertDatabaseHas('categorias', ['nombre' => 'Pinturas']);
    }

    public function test_can_upsert_existing_products_by_code()
    {
        // Crear un producto inicial
        $cat = Categoria::create(['nombre' => 'Herramientas', 'activo' => true]);
        Material::create([
            'codigo' => 'SKU-EXISTING',
            'nombre' => 'Material Viejo',
            'descripcion' => 'Desc Vieja',
            'categoria_id' => $cat->id,
            'unidad' => 'UND',
            'precio_costo' => 100.00,
            'estado' => true
        ]);

        $csvContent = "Codigo,Nombre,Descripcion,Categoria,Unidad,Precio Costo\n"
            . "SKU-EXISTING,Material Actualizado,Nueva Descripcion,Pinturas,GL,250.00\n";

        $file = UploadedFile::fake()->createWithContent('productos.csv', $csvContent);

        $response = $this->postJson('/api/v1/materiales/import', [
            'file' => $file
        ]);

        $response->assertStatus(200);
        $response->assertJson([
            'success' => true,
            'inserted' => 0,
            'updated' => 1
        ]);

        // Verificar que se actualizó
        $this->assertDatabaseHas('materiales', [
            'codigo' => 'SKU-EXISTING',
            'nombre' => 'Material Actualizado',
            'descripcion' => 'Nueva Descripcion',
            'unidad' => 'GL',
            'precio_costo' => 250.00
        ]);
        
        $this->assertDatabaseMissing('materiales', [
            'nombre' => 'Material Viejo'
        ]);
    }

    public function test_fails_on_validation_errors_without_saving_any()
    {
        $csvContent = "Codigo,Nombre,Descripcion,Categoria,Unidad,Precio Costo\n"
            . "SKU-ERR-1,,Falta Nombre,Herramientas,UND,100\n" // Fila 2: error nombre
            . "SKU-ERR-2,Material Sin Unidad,Desc,Herramientas,,150\n" // Fila 3: error unidad
            . "SKU-ERR-3,Material Precio Malo,Desc,Herramientas,GL,no-es-numero\n"; // Fila 4: error precio

        $file = UploadedFile::fake()->createWithContent('productos.csv', $csvContent);

        $response = $this->postJson('/api/v1/materiales/import', [
            'file' => $file
        ]);

        $response->assertStatus(422);
        $response->assertJson([
            'success' => false,
            'message' => 'Se encontraron errores de validación en el archivo.',
            'errors' => [
                'Fila 2' => ['El nombre es obligatorio.'],
                'Fila 3' => ['La unidad es obligatoria.'],
                'Fila 4' => ['El precio de costo debe ser un valor numérico válido.']
            ]
        ]);

        // Asegurar que no se guardó ningún registro (rollback transaccional)
        $this->assertDatabaseMissing('materiales', ['codigo' => 'SKU-ERR-1']);
        $this->assertDatabaseMissing('materiales', ['codigo' => 'SKU-ERR-2']);
        $this->assertDatabaseMissing('materiales', ['codigo' => 'SKU-ERR-3']);
    }
}
