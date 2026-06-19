import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import 'providers/project_form_provider.dart';
import 'widgets/project_general_data_step.dart';
import 'widgets/project_budget_step.dart';
import 'widgets/project_review_step.dart';
import 'widgets/project_bottom_bar.dart';

class ProjectFormScreen extends StatelessWidget {
  const ProjectFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the state down to all the widgets inside this screen
    return ChangeNotifierProvider(
      create: (_) => ProjectFormProvider(),
      child: const _ProjectFormScreenContent(),
    );
  }
}

class _ProjectFormScreenContent extends StatelessWidget {
  const _ProjectFormScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final f = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nuevo Proyecto / Cotización'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withValues(alpha: 0.95),
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: provider.formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: kToolbarHeight + 20),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppTheme.primaryColor,
                            ),
                          ),
                          child: Stepper(
                            type: StepperType.horizontal,
                            currentStep: provider.currentStep,
                            onStepTapped: provider.setStep,
                            onStepContinue: provider.nextStep,
                            onStepCancel: provider.previousStep,
                            elevation: 0,
                            controlsBuilder: (context, details) => const SizedBox.shrink(),
                            steps: [
                              Step(
                                title: const Text('Información'),
                                subtitle: const Text('Datos generales'),
                                isActive: provider.currentStep >= 0,
                                state: provider.currentStep > 0
                                    ? StepState.complete
                                    : StepState.indexed,
                                content: const ProjectGeneralDataStep(),
                              ),
                              Step(
                                title: const Text('Presupuesto'),
                                subtitle: const Text('Partidas y detalles'),
                                isActive: provider.currentStep >= 1,
                                state: provider.currentStep > 1
                                    ? StepState.complete
                                    : StepState.indexed,
                                content: ProjectBudgetStep(formatter: f),
                              ),
                              Step(
                                title: const Text('Resumen'),
                                subtitle: const Text('Costos e impuestos'),
                                isActive: provider.currentStep >= 2,
                                state: provider.currentStep == 2
                                    ? StepState.editing
                                    : StepState.indexed,
                                content: ProjectReviewStep(formatter: f),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ProjectBottomBar(formatter: f),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
