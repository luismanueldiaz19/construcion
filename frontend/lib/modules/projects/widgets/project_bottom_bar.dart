import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../providers/project_form_provider.dart';

class ProjectBottomBar extends StatelessWidget {
  final NumberFormat formatter;

  const ProjectBottomBar({super.key, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectFormProvider>();
    final total = provider.totalFinal;
    final currentStep = provider.currentStep;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TOTAL ESTIMADO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                formatter.format(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (currentStep > 0)
                TextButton(
                  onPressed: provider.previousStep,
                  child: const Text('ATRÁS'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (currentStep < 2) {
                          provider.nextStep();
                        } else {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);

                          final success = await provider.saveProject(context);
                          print('success : $success');

                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Proyecto registrado con éxito!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            navigator.pop(true);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(currentStep == 2 ? 'FINALIZAR' : 'SIGUIENTE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
