import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum DateFilterOption {
  todos,
  ultimos7Dias,
  esteMes,
  mesPasado,
  hace2Meses,
  hace3Meses,
  esteAno,
  anoPasado
}

class QuickDateFilter extends StatelessWidget {
  final DateFilterOption selectedOption;
  final ValueChanged<DateFilterOption> onChanged;

  const QuickDateFilter({
    super.key,
    required this.selectedOption,
    required this.onChanged,
  });

  String _getLabel(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.todos:
        return 'Todos';
      case DateFilterOption.ultimos7Dias:
        return 'Últimos 7 días';
      case DateFilterOption.esteMes:
        return 'Este mes';
      case DateFilterOption.mesPasado:
        return 'Mes pasado';
      case DateFilterOption.hace2Meses:
        return 'Hace 2 meses';
      case DateFilterOption.hace3Meses:
        return 'Hace 3 meses';
      case DateFilterOption.esteAno:
        return 'Este año';
      case DateFilterOption.anoPasado:
        return 'Año pasado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DateFilterOption.values.map((option) {
          final isSelected = selectedOption == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_getLabel(option)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  static bool isDateInFilter(DateTime date, DateFilterOption filter) {
    final now = DateTime.now();
    switch (filter) {
      case DateFilterOption.todos:
        return true;
      case DateFilterOption.ultimos7Dias:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return date.isAfter(sevenDaysAgo) || date.isAtSameMomentAs(sevenDaysAgo);
      case DateFilterOption.esteMes:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
               date.isBefore(end.add(const Duration(seconds: 1)));
      case DateFilterOption.mesPasado:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        return date.isAfter(lastMonthStart.subtract(const Duration(seconds: 1))) && 
               date.isBefore(lastMonthEnd.add(const Duration(seconds: 1)));
      case DateFilterOption.hace2Meses:
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
               date.isBefore(end.add(const Duration(seconds: 1)));
      case DateFilterOption.hace3Meses:
        final start = DateTime(now.year, now.month - 3, 1);
        final end = DateTime(now.year, now.month - 2, 0, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
               date.isBefore(end.add(const Duration(seconds: 1)));
      case DateFilterOption.esteAno:
        final start = DateTime(now.year, 1, 1);
        return date.isAfter(start.subtract(const Duration(seconds: 1)));
      case DateFilterOption.anoPasado:
        final start = DateTime(now.year - 1, 1, 1);
        final end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
               date.isBefore(end.add(const Duration(seconds: 1)));
    }
  }
}
