import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_button.dart';
import '../providers/project_form_provider.dart';

/// Barra inferior fija con el total estimado y botones de navegación del asistente.
class ProjectBottomBar extends StatelessWidget {
  final NumberFormat formatter;

  const ProjectBottomBar({super.key, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final currentStep = provider.currentStep;
    final isLastStep = currentStep == 2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TOTAL ESTIMADO',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatter.format(provider.totalFinal),
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (currentStep > 0) ...[
                    AppButton(
                      text: 'Atrás',
                      icon: Icons.arrow_back_rounded,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.compact,
                      borderRadius: 9,
                      onPressed: provider.isLoading
                          ? null
                          : provider.previousStep,
                    ),
                    const SizedBox(width: 8),
                  ],
                  AppButton(
                    text: isLastStep ? 'Finalizar' : 'Siguiente',
                    icon: isLastStep
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    variant: isLastStep
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    borderRadius: 9,
                    isLoading: provider.isLoading,
                    onPressed: () => _handlePrimaryAction(context, provider),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    ProjectFormProvider provider,
  ) async {
    if (provider.currentStep < 2) {
      provider.nextStep();
      return;
    }

    final navigator = Navigator.of(context);
    final success = await provider.saveProject(context);

    if (success && context.mounted) {
      AppAlert.showToast(
        context,
        '¡Proyecto registrado con éxito!',
        type: AppAlertType.success,
      );
      navigator.pop(true);
    }
  }
}
