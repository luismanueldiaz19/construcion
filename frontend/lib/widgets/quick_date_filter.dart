import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum DateFilterOption {
  todos,
  esteMes,
  mesPasado,
  ultimos7Dias,
  ultimos30Dias,
  hace2Meses,
  hace3Meses,
  esteAno,
  anoPasado,
}

class _FilterMenuData {
  final String label;
  final IconData icon;
  const _FilterMenuData(this.label, this.icon);
}

class QuickDateFilter extends StatelessWidget {
  final DateFilterOption selectedOption;
  final ValueChanged<DateFilterOption> onChanged;

  const QuickDateFilter({
    super.key,
    required this.selectedOption,
    required this.onChanged,
  });

  _FilterMenuData _getMenuData(DateFilterOption option) {
    switch (option) {
      case DateFilterOption.todos:
        return const _FilterMenuData('Todos', Icons.all_inclusive);
      case DateFilterOption.esteMes:
        return const _FilterMenuData('Este Mes', Icons.calendar_today);
      case DateFilterOption.mesPasado:
        return const _FilterMenuData('Mes Pasado', Icons.history);
      case DateFilterOption.ultimos7Dias:
        return const _FilterMenuData('Últimos 7 días', Icons.view_column);
      case DateFilterOption.ultimos30Dias:
        return const _FilterMenuData('Últimos 30 días', Icons.calendar_month);
      case DateFilterOption.hace2Meses:
        return const _FilterMenuData('Últimos 2 meses', Icons.grid_view);
      case DateFilterOption.hace3Meses:
        return const _FilterMenuData('Últimos 3 meses', Icons.grid_on);
      case DateFilterOption.esteAno:
        return const _FilterMenuData('Este Año', Icons.star_border);
      case DateFilterOption.anoPasado:
        return const _FilterMenuData('Año Pasado', Icons.history_toggle_off);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<DateFilterOption>(
        tooltip: 'Filtros rápidos',
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        elevation: 4,
        onSelected: onChanged,
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, color: Color(0xFF1E293B)),
        ),
        itemBuilder: (context) => [
          _buildMenuItem(DateFilterOption.esteMes),
          _buildMenuItem(DateFilterOption.mesPasado),
          const PopupMenuDivider(),
          _buildMenuItem(DateFilterOption.ultimos7Dias),
          _buildMenuItem(DateFilterOption.ultimos30Dias),
          _buildMenuItem(DateFilterOption.hace2Meses),
          _buildMenuItem(DateFilterOption.hace3Meses),
          const PopupMenuDivider(),
          _buildMenuItem(DateFilterOption.esteAno),
          const PopupMenuDivider(),
          _buildMenuItem(DateFilterOption.anoPasado),
          _buildMenuItem(DateFilterOption.todos),
        ],
      ),
    );
  }

  PopupMenuItem<DateFilterOption> _buildMenuItem(DateFilterOption option) {
    final data = _getMenuData(option);
    final isSelected = selectedOption == option;
    return PopupMenuItem<DateFilterOption>(
      value: option,
      child: Row(
        children: [
          Icon(
            data.icon,
            size: 20,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Text(
            data.label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
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
        return date.isAfter(sevenDaysAgo) ||
            date.isAtSameMomentAs(sevenDaysAgo);
      case DateFilterOption.ultimos30Dias:
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return date.isAfter(thirtyDaysAgo) ||
            date.isAtSameMomentAs(thirtyDaysAgo);
      case DateFilterOption.esteMes:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
      case DateFilterOption.mesPasado:
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
        return date.isAfter(
              lastMonthStart.subtract(const Duration(seconds: 1)),
            ) &&
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
