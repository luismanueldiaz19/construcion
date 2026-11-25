import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_confirm_dialog.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_status_badge.dart';
import 'providers/project_form_provider.dart';
import 'widgets/project_bottom_bar.dart';
import 'widgets/project_budget_step.dart';
import 'widgets/project_general_data_step.dart';
import 'widgets/project_review_step.dart';
import 'widgets/project_step_header.dart';

/// Pantalla de creación de Nuevo Proyecto / Cotización con asistente de 3 pasos.
class ProjectFormScreen extends StatelessWidget {
  const ProjectFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectFormProvider(),
      child: const _ProjectFormScreenContent(),
    );
  }
}

class _ProjectFormScreenContent extends StatelessWidget {
  const _ProjectFormScreenContent();

  static const List<ProjectStepItem> _steps = [
    ProjectStepItem(
      title: 'Información',
      subtitle: 'Datos generales',
      icon: Icons.info_outline_rounded,
    ),
    ProjectStepItem(
      title: 'Presupuesto',
      subtitle: 'Partidas e ítems',
      icon: Icons.list_alt_rounded,
    ),
    ProjectStepItem(
      title: 'Resumen',
      subtitle: 'Costos e impuestos',
      icon: Icons.summarize_outlined,
    ),
  ];

  Future<void> _handleBack(
    BuildContext context,
    ProjectFormProvider provider,
  ) async {
    if (!provider.hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await AppConfirmDialog.show(
      context,
      title: '¿Salir sin guardar?',
      message:
          'Tienes cambios sin guardar en este proyecto. Si sales ahora se perderán.',
      confirmText: 'Sí, salir',
      cancelText: 'Seguir editando',
      isDestructive: true,
      icon: Icons.exit_to_app_rounded,
    );

    if (discard && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final currencyFmt = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
    final activeStep = _steps[provider.currentStep];

    return PopScope(
      canPop: !provider.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack(context, provider);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeaderBar(
          title: 'NUEVO PROYECTO',
          subtitle:
              'Paso ${provider.currentStep + 1} de ${_steps.length} · ${activeStep.subtitle}',
          badgeLetter: 'P',
          showMenuButton: false,
          onBack: () => _handleBack(context, provider),
          actions: [
            AppStatusBadge(
              label: provider.estado.toUpperCase(),
              type: AppStatusType.pending,
            ),
          ],
        ),
        body: Form(
          key: provider.formKey,
          child: Column(
            children: [
              ProjectStepHeader(
                currentStep: provider.currentStep,
                steps: _steps,
                onStepTapped: provider.setStep,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: IndexedStack(
                      index: provider.currentStep,
                      sizing: StackFit.expand,
                      children: [
                        const SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 20),
                          child: ProjectGeneralDataStep(),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          child: ProjectBudgetStep(formatter: currencyFmt),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          child: ProjectReviewStep(formatter: currencyFmt),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ProjectBottomBar(formatter: currencyFmt),
            ],
          ),
        ),
      ),
    );
  }
}
