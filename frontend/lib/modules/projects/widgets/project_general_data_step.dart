import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/app_date_picker_field.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../widgets/app_text_field.dart';
import '../providers/project_form_provider.dart';
import 'client_selector.dart';

/// Paso 1: Datos generales integrados directamente a la pantalla.
class ProjectGeneralDataStep extends StatelessWidget {
  const ProjectGeneralDataStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 620;

        final nombreField = _LabeledInput(
          label: 'Nombre del Proyecto *',
          child: AppTextField(
            controller: provider.nombreController,
            hintText: 'EJ: RESIDENCIAL VISTA MAR - TORRE A',
            prefixIconData: Icons.apartment_rounded,
            uppercase: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),
        );

        final estadoField = AppDropdown<String>(
          labelText: 'Estado Inicial',
          value: provider.estado,
          prefixIconData: Icons.flag_outlined,
          items: const [
            DropdownMenuItem(value: 'Cotización', child: Text('Cotización')),
          ],
          onChanged: (v) => provider.setEstado(v ?? 'Cotización'),
        );

        final clientField = ClientSelector(
          initialClient: provider.selectedClient,
          onChanged: provider.setClient,
        );

        final ubicacionField = _LabeledInput(
          label: 'Ubicación',
          child: AppTextField(
            controller: provider.ubicacionController,
            hintText: 'EJ: SANTO DOMINGO ESTE, RD',
            prefixIconData: Icons.location_on_outlined,
            uppercase: true,
          ),
        );

        final fechaInicioField = AppDatePickerField(
          labelText: 'Fecha de Inicio',
          selectedDate: provider.fechaInicio,
          onDateChanged: provider.setFechaInicio,
        );

        final fechaFinField = AppDatePickerField(
          labelText: 'Fecha Estimada de Fin',
          selectedDate: provider.fechaFin,
          firstDate: provider.fechaInicio,
          onDateChanged: provider.setFechaFin,
        );

        final notasField = _LabeledInput(
          label: 'Observaciones / Notas',
          child: AppTextField(
            controller: provider.notasController,
            hintText: 'CONDICIONES COMERCIALES, ALCANCE O NOTAS RELEVANTES...',
            uppercase: true,
            maxLines: 3,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Datos Generales de la Obra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Información base del proyecto o cotización',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const Divider(height: 18, color: Color(0xFFE2E8F0)),
            if (isMobile) ...[
              nombreField,
              const SizedBox(height: 10),
              estadoField,
              const SizedBox(height: 10),
              clientField,
              const SizedBox(height: 10),
              ubicacionField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: fechaInicioField),
                  const SizedBox(width: 10),
                  Expanded(child: fechaFinField),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: nombreField),
                  const SizedBox(width: 12),
                  Expanded(child: estadoField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: clientField),
                  const SizedBox(width: 12),
                  Expanded(child: ubicacionField),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fechaInicioField),
                  const SizedBox(width: 12),
                  Expanded(child: fechaFinField),
                ],
              ),
            ],
            const SizedBox(height: 12),
            notasField,
          ],
        );
      },
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledInput({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}
