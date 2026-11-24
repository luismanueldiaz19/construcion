import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Campo de selección de fecha global estandarizado.
///
/// Formatea automáticamente en formato dd/MM/yyyy y despliega el calendario
/// nativo de Flutter con los colores del tema corporativo.
class AppDatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateChanged;
  final String? labelText;
  final String hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isClearable;
  final bool isDark;
  final double borderRadius;
  final String? Function(DateTime?)? validator;

  const AppDatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.labelText,
    this.hintText = 'dd/mm/aaaa',
    this.firstDate,
    this.lastDate,
    this.isClearable = true,
    this.isDark = false,
    this.borderRadius = 10.0,
    this.validator,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedDate ?? now;
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color fillColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white;
    final Color textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final Color hintColor = isDark ? Colors.white54 : AppTheme.textSecondary;
    final Color iconColor = isDark ? Colors.white54 : Colors.grey.shade600;

    final hasDate = selectedDate != null;
    final textValue = hasDate ? _formatDate(selectedDate!) : '';

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: isDark
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 1.0),
    );

    final inputWidget = InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor, fontSize: 12.5),
          filled: true,
          fillColor: fillColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: border,
          enabledBorder: border,
          prefixIcon: Icon(Icons.calendar_today_rounded, size: 17, color: iconColor),
          suffixIcon: (isClearable && hasDate)
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  color: iconColor,
                  onPressed: () => onDateChanged(null),
                )
              : null,
        ),
        child: Text(
          textValue.isEmpty ? hintText : textValue,
          style: TextStyle(
            color: textValue.isEmpty ? hintColor : textColor,
            fontSize: 12.5,
          ),
        ),
      ),
    );

    if (labelText == null) {
      return inputWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelText!,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        inputWidget,
      ],
    );
  }
}
