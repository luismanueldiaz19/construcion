import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../providers/project_form_provider.dart';
import 'client_selector.dart';

class ProjectGeneralDataStep extends StatelessWidget {
  const ProjectGeneralDataStep({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();

    return Column(
      children: [
        _buildSectionTitle(Icons.info_outline, 'Datos Generales'),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return Column(
                  children: [
                    if (isMobile) ...[
                      _buildTextField(
                        controller: provider.nombreController,
                        label: 'Nombre del Proyecto',
                        icon: Icons.business,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildEstadoDropdown(provider),
                      const SizedBox(height: 16),
                      ClientSelector(
                        initialClient: provider.selectedClient,
                        onChanged: provider.setClient,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: provider.ubicacionController,
                        label: 'Ubicación',
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        context,
                        label: 'Fecha de Inicio',
                        selectedDate: provider.fechaInicio,
                        onDateSelected: provider.setFechaInicio,
                      ),
                      const SizedBox(height: 16),
                      _buildDatePicker(
                        context,
                        label: 'Fecha Estimada de Fin',
                        selectedDate: provider.fechaFin,
                        onDateSelected: provider.setFechaFin,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: provider.nombreController,
                              label: 'Nombre del Proyecto',
                              icon: Icons.business,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Campo requerido'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: _buildEstadoDropdown(provider)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClientSelector(
                              initialClient: provider.selectedClient,
                              onChanged: provider.setClient,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: provider.ubicacionController,
                              label: 'Ubicación',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              context,
                              label: 'Fecha de Inicio',
                              selectedDate: provider.fechaInicio,
                              onDateSelected: provider.setFechaInicio,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDatePicker(
                              context,
                              label: 'Fecha Estimada de Fin',
                              selectedDate: provider.fechaFin,
                              onDateSelected: provider.setFechaFin,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: provider.notasController,
                      label: 'Observaciones / Notas',
                      icon: Icons.note_alt_outlined,
                      maxLines: 4,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoDropdown(ProjectFormProvider provider) {
    return DropdownButtonFormField<String>(
      value: provider.estado,
      decoration: InputDecoration(
        labelText: 'Estado Inicial',
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        'Cotización',
      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => provider.setEstado(v ?? 'Cotización'),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker(BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    final dateStr = selectedDate != null
        ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
        : "";
    
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) onDateSelected(date);
      },
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(dateStr),
          initialValue: dateStr,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, size: 20),
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
