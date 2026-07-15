<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\Payroll;
use App\Models\PayrollDetail;
use App\Models\PayrollLoan;
use App\Models\EmployeeSalaryHistory;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;

/**
 * TAREA 09 — NominaExportController
 *
 * Exportaciones Excel para uso del contador/RRHH.
 * Usa PhpSpreadsheet (incluido con Laravel).
 *
 * Reportes disponibles:
 *  1. Nómina consolidada por periodo
 *  2. Planilla TSS (formato requerido por TSS)
 *  3. Historial de salarios por empleado
 *  4. Retenciones ISR del periodo
 *  5. Provisiones acumuladas (regalía, vacaciones, cesantía)
 *  6. Libro de nómina / Kardex del empleado
 */
class NominaExportController extends Controller
{
    private array $headerStyle = [
        'font'      => ['bold' => true, 'color' => ['rgb' => 'FFFFFF'], 'size' => 11],
        'fill'      => ['fillType' => Fill::FILL_SOLID, 'color' => ['rgb' => '1E3A5F']],
        'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER, 'vertical' => Alignment::VERTICAL_CENTER],
        'borders'   => ['allBorders' => ['borderStyle' => Border::BORDER_THIN]],
    ];

    private array $subHeaderStyle = [
        'font'      => ['bold' => true, 'size' => 10],
        'fill'      => ['fillType' => Fill::FILL_SOLID, 'color' => ['rgb' => 'D6E4F0']],
        'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        'borders'   => ['allBorders' => ['borderStyle' => Border::BORDER_THIN]],
    ];

    private array $dataStyle = [
        'borders'   => ['allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'CCCCCC']]],
        'alignment' => ['vertical' => Alignment::VERTICAL_CENTER],
    ];

    // ───────────────────────────────────────────────
    //  1. NÓMINA CONSOLIDADA POR PERIODO
    // ───────────────────────────────────────────────
    public function nominaConsolidada(Request $request): Response
    {
        $request->validate([
            'payroll_id' => 'required|exists:payrolls,id',
        ]);

        $reportService = new \App\Services\NominaReportService();
        $data = $reportService->getNominaConsolidada($request->payroll_id);

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Nómina Consolidada');

        // Título
        $sheet->mergeCells('A1:M1');
        $sheet->setCellValue('A1', $data['meta']['title']);
        $sheet->getStyle('A1')->applyFromArray([
            'font'      => ['bold' => true, 'size' => 14, 'color' => ['rgb' => '1E3A5F']],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);

        $sheet->mergeCells('A2:M2');
        $sheet->setCellValue('A2', $data['meta']['subtitle']);
        $sheet->getStyle('A2')->applyFromArray([
            'font'      => ['italic' => true, 'size' => 10],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);

        // Encabezados
        $headers = [
            'A' => 'Código', 'B' => 'Empleado', 'C' => 'Departamento',
            'D' => 'Salario Base', 'E' => 'HE / Variables', 'F' => 'TOTAL BRUTO',
            'G' => 'TSS SFS Emp.', 'H' => 'AFP Emp.', 'I' => 'ISR',
            'J' => 'Préstamos', 'K' => 'Total Deducc.', 'L' => 'NETO A PAGAR',
            'M' => 'Costo Patronal',
        ];

        $row = 4;
        foreach ($headers as $col => $label) {
            $sheet->setCellValue("{$col}{$row}", $label);
        }
        $sheet->getStyle("A{$row}:M{$row}")->applyFromArray($this->headerStyle);
        $sheet->getRowDimension($row)->setRowHeight(20);

        $row = 5;

        foreach ($data['rows'] as $r) {
            $values = [
                $r['sal_base'], $r['he_var'], $r['bruto'], $r['tss_sfs'],
                $r['afp'], $r['isr'], $r['prestamo'], $r['total_ded'],
                $r['neto'], $r['patronal']
            ];
            $cols   = ['D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'];

            $sheet->setCellValue("A{$row}", $r['codigo']);
            $sheet->setCellValue("B{$row}", $r['empleado']);
            $sheet->setCellValue("C{$row}", $r['departamento']);

            foreach ($cols as $i => $col) {
                $sheet->setCellValue("{$col}{$row}", $values[$i]);
                $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
            }

            $sheet->getStyle("A{$row}:M{$row}")->applyFromArray($this->dataStyle);
            $row % 2 === 0 && $sheet->getStyle("A{$row}:M{$row}")->getFill()
                ->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('F8FBFF');

            $row++;
        }

        // Fila de totales
        $sheet->setCellValue("B{$row}", 'TOTALES');
        $sheet->getStyle("A{$row}:M{$row}")->applyFromArray($this->subHeaderStyle);
        
        $totals = $data['totals'];
        $totalValues = [
            'D' => $totals['sal_base'], 'E' => $totals['he_var'], 'F' => $totals['bruto'], 
            'G' => $totals['tss_sfs'], 'H' => $totals['afp'], 'I' => $totals['isr'], 
            'J' => $totals['prestamo'], 'K' => $totals['total_ded'], 'L' => $totals['neto'], 
            'M' => $totals['patronal']
        ];

        foreach ($totalValues as $col => $total) {
            $sheet->setCellValue("{$col}{$row}", $total);
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
        }

        $this->autoSizeColumns($sheet, range('A', 'M'));

        return $this->downloadSpreadsheet($spreadsheet, "nomina_consolidada_{$request->payroll_id}");
    }

    // ───────────────────────────────────────────────
    //  2. PLANILLA TSS
    // ───────────────────────────────────────────────
    public function planillaTSS(Request $request): Response
    {
        $request->validate(['payroll_id' => 'required|exists:payrolls,id']);

        $reportService = new \App\Services\NominaReportService();
        $data = $reportService->getPlanillaTSS($request->payroll_id);

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Planilla TSS');

        $sheet->mergeCells('A1:J1');
        $sheet->setCellValue('A1', $data['meta']['title']);
        $sheet->getStyle('A1')->applyFromArray(['font' => ['bold' => true, 'size' => 13], 'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);

        $sheet->mergeCells('A2:J2');
        $sheet->setCellValue('A2', $data['meta']['subtitle']);
        $sheet->getStyle('A2')->applyFromArray(['alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);

        $headers = ['No.', 'No. TSS', 'Nombre Completo', 'AFP', 'ARS', 'Salario Cotizable', 'AFP Emp.', 'SFS Emp.', 'AFP Patron.', 'SFS Patron.'];
        $row = 4;
        $col = 'A';
        foreach ($headers as $h) {
            $sheet->setCellValue("{$col}{$row}", $h);
            $col++;
        }
        $sheet->getStyle("A{$row}:J{$row}")->applyFromArray($this->headerStyle);

        $row = 5;
        foreach ($data['rows'] as $r) {
            $sheet->setCellValue("A{$row}", $r['num']);
            $sheet->setCellValue("B{$row}", $r['no_tss']);
            $sheet->setCellValue("C{$row}", $r['nombre']);
            $sheet->setCellValue("D{$row}", $r['afp']);
            $sheet->setCellValue("E{$row}", $r['ars']);
            $sheet->setCellValue("F{$row}", $r['sal_cotizable']);
            $sheet->setCellValue("G{$row}", $r['afp_emp']);
            $sheet->setCellValue("H{$row}", $r['sfs_emp']);
            $sheet->setCellValue("I{$row}", $r['afp_patron']);
            $sheet->setCellValue("J{$row}", $r['sfs_patron']);

            foreach (['F','G','H','I','J'] as $c) {
                $sheet->getStyle("{$c}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
            }
            $sheet->getStyle("A{$row}:J{$row}")->applyFromArray($this->dataStyle);
            $row++;
        }

        // Fila de totales
        $sheet->mergeCells("A{$row}:E{$row}");
        $sheet->setCellValue("A{$row}", 'TOTALES GENERALES');
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_RIGHT);
        $sheet->getStyle("A{$row}")->getFont()->setBold(true);

        $totals = $data['totals'];
        $sheet->setCellValue("F{$row}", $totals['sal_cotizable']);
        $sheet->setCellValue("G{$row}", $totals['afp_emp']);
        $sheet->setCellValue("H{$row}", $totals['sfs_emp']);
        $sheet->setCellValue("I{$row}", $totals['afp_patron']);
        $sheet->setCellValue("J{$row}", $totals['sfs_patron']);

        foreach (['F','G','H','I','J'] as $c) {
            $sheet->getStyle("{$c}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
        }
        $sheet->getStyle("A{$row}:J{$row}")->applyFromArray($this->subHeaderStyle);

        $this->autoSizeColumns($sheet, range('A', 'J'));
        return $this->downloadSpreadsheet($spreadsheet, "planilla_tss_{$request->payroll_id}");
    }

    // ───────────────────────────────────────────────
    //  3. HISTORIAL DE SALARIOS
    // ───────────────────────────────────────────────
    public function historialSalarios(Request $request): Response
    {
        $reportService = new \App\Services\NominaReportService();
        $data = $reportService->getHistorialSalarios(
            $request->employee_id,
            $request->from,
            $request->to
        );

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Historial Salarios');

        $sheet->mergeCells('A1:H1');
        $sheet->setCellValue('A1', $data['meta']['title']);
        $sheet->getStyle('A1')->applyFromArray(['font' => ['bold' => true, 'size' => 13], 'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);

        if ($data['meta']['subtitle']) {
            $sheet->mergeCells('A2:H2');
            $sheet->setCellValue('A2', $data['meta']['subtitle']);
            $sheet->getStyle('A2')->applyFromArray(['alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);
        }

        $headers = ['Empleado', 'Código', 'Departamento', 'Fecha Efectiva', 'Salario Anterior', 'Salario Nuevo', 'Diferencia', 'Motivo', 'Aprobado Por'];
        $row = 3;
        $col = 'A';
        foreach ($headers as $h) {
            $sheet->setCellValue("{$col}{$row}", $h);
            $col++;
        }
        $sheet->getStyle("A{$row}:I{$row}")->applyFromArray($this->headerStyle);

        $row = 4;
        foreach ($data['rows'] as $r) {
            $sheet->setCellValue("A{$row}", $r['empleado']);
            $sheet->setCellValue("B{$row}", $r['codigo']);
            $sheet->setCellValue("C{$row}", $r['departamento']);
            $sheet->setCellValue("D{$row}", \Carbon\Carbon::parse($r['fecha_efectiva'])->format('d/m/Y'));
            $sheet->setCellValue("E{$row}", $r['salario_anterior']);
            $sheet->setCellValue("F{$row}", $r['salario_nuevo']);
            $sheet->setCellValue("G{$row}", $r['diferencia']);
            $sheet->setCellValue("H{$row}", $r['motivo']);
            $sheet->setCellValue("I{$row}", $r['aprobado_por']);

            foreach (['E','F','G'] as $c) {
                $sheet->getStyle("{$c}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
            }

            // Color según si fue aumento o reducción
            if ($r['diferencia'] > 0) {
                $sheet->getStyle("G{$row}")->getFont()->getColor()->setRGB('006400');
            } elseif ($r['diferencia'] < 0) {
                $sheet->getStyle("G{$row}")->getFont()->getColor()->setRGB('8B0000');
            }

            $sheet->getStyle("A{$row}:I{$row}")->applyFromArray($this->dataStyle);
            $row++;
        }

        $this->autoSizeColumns($sheet, range('A', 'I'));
        return $this->downloadSpreadsheet($spreadsheet, 'historial_salarios_' . now()->format('Ymd'));
    }

    // ───────────────────────────────────────────────
    //  4. RETENCIONES ISR
    // ───────────────────────────────────────────────
    public function retencionesISR(Request $request): Response
    {
        $request->validate([
            'payroll_id' => 'required|exists:payrolls,id',
        ]);

        $reportService = new \App\Services\NominaReportService();
        $data = $reportService->getRetencionesISR($request->payroll_id);

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Retenciones ISR');

        $sheet->mergeCells('A1:F1');
        $sheet->setCellValue('A1', $data['meta']['title']);
        $sheet->getStyle('A1')->applyFromArray(['font' => ['bold' => true, 'size' => 13], 'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);

        $headers = ['Código', 'Empleado', 'Departamento', 'Ingreso Bruto', 'ISR Retenido', 'ISR Anualizado Estimado'];
        $row = 3;
        $col = 'A';
        foreach ($headers as $h) {
            $sheet->setCellValue("{$col}{$row}", $h);
            $col++;
        }
        $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($this->headerStyle);

        $row = 4;
        foreach ($data['rows'] as $r) {
            $sheet->setCellValue("A{$row}", $r['codigo']);
            $sheet->setCellValue("B{$row}", $r['empleado']);
            $sheet->setCellValue("C{$row}", $r['departamento']);
            $sheet->setCellValue("D{$row}", $r['ingreso_bruto']);
            $sheet->setCellValue("E{$row}", $r['isr_retenido']);
            $sheet->setCellValue("F{$row}", $r['isr_anualizado']);

            foreach (['D','E','F'] as $c) {
                $sheet->getStyle("{$c}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
            }
            $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($this->dataStyle);
            $row++;
        }

        // Total
        $sheet->setCellValue("B{$row}", 'TOTAL ISR');
        $sheet->setCellValue("E{$row}", $data['totals']['isr_retenido']);
        $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($this->subHeaderStyle);
        $sheet->getStyle("E{$row}")->getNumberFormat()->setFormatCode('#,##0.00');

        $this->autoSizeColumns($sheet, range('A', 'F'));
        return $this->downloadSpreadsheet($spreadsheet, "retenciones_isr_{$request->payroll_id}");
    }

    // ───────────────────────────────────────────────
    //  5. PROVISIONES ACUMULADAS
    // ───────────────────────────────────────────────
    public function provisiones(Request $request): Response
    {
        $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after_or_equal:from',
        ]);

        $reportService = new \App\Services\NominaReportService();
        $data = $reportService->getProvisiones($request->from, $request->to);

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Provisiones');

        $sheet->mergeCells('A1:G1');
        $sheet->setCellValue('A1', "PROVISIONES LABORALES ACUMULADAS — {$request->from} al {$request->to}");
        $sheet->getStyle('A1')->applyFromArray(['font' => ['bold' => true, 'size' => 13], 'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);

        $headers = ['Código', 'Empleado', 'Departamento', 'Prov. Regalía', 'Prov. Vacaciones', 'Prov. Cesantía', 'TOTAL PROVISIONES'];
        $row = 3;
        $col = 'A';
        foreach ($headers as $h) {
            $sheet->setCellValue("{$col}{$row}", $h);
            $col++;
        }
        $sheet->getStyle("A{$row}:G{$row}")->applyFromArray($this->headerStyle);

        $row = 4;
        foreach ($data['rows'] as $r) {
            $sheet->setCellValue("A{$row}", $r['codigo']);
            $sheet->setCellValue("B{$row}", $r['empleado']);
            $sheet->setCellValue("C{$row}", $r['departamento']);
            $sheet->setCellValue("D{$row}", $r['prov_regalia']);
            $sheet->setCellValue("E{$row}", $r['prov_vacaciones']);
            $sheet->setCellValue("F{$row}", $r['prov_cesantia']);
            $sheet->setCellValue("G{$row}", $r['total_prov']);

            foreach (['D','E','F','G'] as $c) {
                $sheet->getStyle("{$c}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
            }
            $sheet->getStyle("A{$row}:G{$row}")->applyFromArray($this->dataStyle);
            $row++;
        }

        $sheet->setCellValue("B{$row}", 'TOTALES');
        $sheet->setCellValue("D{$row}", $data['totals']['regalia']);
        $sheet->setCellValue("E{$row}", $data['totals']['vacaciones']);
        $sheet->setCellValue("F{$row}", $data['totals']['cesantia']);
        $sheet->setCellValue("G{$row}", $data['totals']['total']);
        $sheet->getStyle("A{$row}:G{$row}")->applyFromArray($this->subHeaderStyle);
        foreach (['D','E','F','G'] as $c) {
            $sheet->getStyle("{$c}{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
        }

        $this->autoSizeColumns($sheet, range('A', 'G'));
        return $this->downloadSpreadsheet($spreadsheet, 'provisiones_' . str_replace('-', '', $request->from));
    }

    // ───────────────────────────────────────────────
    //  6. KARDEX / LIBRO DE NÓMINA DEL EMPLEADO
    // ───────────────────────────────────────────────
    public function kardex(Request $request): Response
    {
        $request->validate([
            'employee_id' => 'required|exists:employees,id',
            'from'        => 'required|date',
            'to'          => 'required|date|after_or_equal:from',
        ]);

        $employee = Employee::with(['department', 'position'])->findOrFail($request->employee_id);

        $details = PayrollDetail::where('employee_id', $employee->id)
            ->whereHas('payroll', function ($q) use ($request) {
                $q->whereHas('period', fn($p) => $p->whereBetween('payment_date', [$request->from, $request->to]));
            })
            ->with(['payroll.period', 'concept'])
            ->orderBy('created_at')
            ->get()
            ->groupBy(fn($d) => $d->payroll->period->start_date);

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Kardex Empleado');

        $sheet->mergeCells('A1:E1');
        $sheet->setCellValue('A1', "KARDEX / LIBRO DE NÓMINA — {$employee->full_name} ({$employee->employee_code})");
        $sheet->getStyle('A1')->applyFromArray(['font' => ['bold' => true, 'size' => 12], 'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER]]);

        $sheet->mergeCells('A2:E2');
        $sheet->setCellValue('A2', "Cargo: {$employee->position?->title} | Dpto: {$employee->department?->name} | Periodo: {$request->from} — {$request->to}");
        $sheet->getStyle('A2')->applyFromArray(['alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER], 'font' => ['italic' => true]]);

        $row = 4;
        foreach ($details as $period => $periodDetails) {
            // Cabecera del periodo
            $sheet->mergeCells("A{$row}:E{$row}");
            $sheet->setCellValue("A{$row}", "Periodo: {$period}");
            $sheet->getStyle("A{$row}:E{$row}")->applyFromArray($this->subHeaderStyle);
            $row++;

            $headers = ['Tipo', 'Concepto', 'Cantidad', 'Tarifa', 'Monto'];
            $col = 'A';
            foreach ($headers as $h) {
                $sheet->setCellValue("{$col}{$row}", $h);
                $col++;
            }
            $sheet->getStyle("A{$row}:E{$row}")->applyFromArray($this->headerStyle);
            $row++;

            foreach ($periodDetails as $detail) {
                $sheet->setCellValue("A{$row}", ucfirst($detail->type));
                $sheet->setCellValue("B{$row}", $detail->concept?->name ?? 'Desconocido');
                $sheet->setCellValue("C{$row}", $detail->quantity);
                $sheet->setCellValue("D{$row}", $detail->rate ?? '—');
                $sheet->setCellValue("E{$row}", $detail->amount);
                $sheet->getStyle("E{$row}")->getNumberFormat()->setFormatCode('#,##0.00');
                $sheet->getStyle("A{$row}:E{$row}")->applyFromArray($this->dataStyle);
                $row++;
            }

            $bruto = $periodDetails->where('type', 'ingreso')->sum('amount');
            $deds  = $periodDetails->where('type', 'deduccion')->sum('amount');
            $neto  = $bruto - $deds;

            $sheet->mergeCells("A{$row}:D{$row}");
            $sheet->setCellValue("A{$row}", 'NETO DEL PERIODO');
            $sheet->setCellValue("E{$row}", $neto);
            $sheet->getStyle("A{$row}:E{$row}")->applyFromArray($this->subHeaderStyle);
            $sheet->getStyle("E{$row}")->getNumberFormat()->setFormatCode('#,##0.00');

            $row += 2;
        }

        $this->autoSizeColumns($sheet, range('A', 'E'));
        return $this->downloadSpreadsheet($spreadsheet, "kardex_{$employee->employee_code}");
    }

    // ───────────────────────────────────────────────
    //  HELPERS PRIVADOS
    // ───────────────────────────────────────────────

    private function autoSizeColumns(object $sheet, array $columns): void
    {
        foreach ($columns as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }
    }

    private function downloadSpreadsheet(Spreadsheet $spreadsheet, string $filename): Response
    {
        $writer = new Xlsx($spreadsheet);
        $fullFilename = $filename . '_' . now()->format('Ymd_His') . '.xlsx';

        ob_start();
        $writer->save('php://output');
        $content = ob_get_clean();

        return response($content, 200, [
            'Content-Type'        => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => "attachment; filename=\"{$fullFilename}\"",
            'Cache-Control'       => 'max-age=0',
        ]);
    }
}
