import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

/// Definición inmutable de cada paso del asistente de creación de proyecto.
class ProjectStepItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const ProjectStepItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Barra de pasos horizontal compacta, responsiva y sin desbordamientos.
class ProjectStepHeader extends StatelessWidget {
  final int currentStep;
  final List<ProjectStepItem> steps;
  final ValueChanged<int> onStepTapped;

  const ProjectStepHeader({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final leftStep = index ~/ 2;
                final isCompleted = currentStep > leftStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successColor
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final step = steps[stepIndex];
              final isActive = currentStep == stepIndex;
              final isCompleted = currentStep > stepIndex;

              return _StepChip(
                index: stepIndex,
                step: step,
                isActive: isActive,
                isCompleted: isCompleted,
                onTap: () => onStepTapped(stepIndex),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final int index;
  final ProjectStepItem step;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _StepChip({
    required this.index,
    required this.step,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;
    final Color circleColor = isCompleted
        ? AppTheme.successColor
        : isActive
        ? AppTheme.accentColor
        : const Color(0xFFE2E8F0);
    final Color textColor = isActive
        ? AppTheme.textPrimary
        : isCompleted
        ? AppTheme.successColor
        : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: isCompact ? 11.5 : 12.5,
                    fontWeight: isActive || isCompleted
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (!isCompact)
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
