import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Selector desplegable tipado global para el sistema.
///
/// Cumple con las directrices de tamaño compacto (38-40px de altura),
/// previene el aplastamiento y soporta etiquetas superiores y estados de error.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final IconData? prefixIconData;
  final String? Function(T?)? validator;
  final bool isDark;
  final double borderRadius;
  final bool isExpanded;

  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.prefixIconData,
    this.validator,
    this.isDark = false,
    this.borderRadius = 10.0,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color fillColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white;
    final Color textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final Color hintColor = isDark ? Colors.white54 : AppTheme.textSecondary;
    final Color iconColor = isDark ? Colors.white54 : Colors.grey.shade600;

    Widget? prefix;
    if (prefixIcon != null) {
      prefix = prefixIcon;
    } else if (prefixIconData != null) {
      prefix = Icon(prefixIconData, color: iconColor, size: 18);
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: isDark
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 1.0),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    );

    final dropdownField = DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      dropdownColor: isDark ? const Color(0xFF24272C) : Colors.white,
      style: TextStyle(color: textColor, fontSize: 13),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: iconColor,
        size: 20,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: 12.5),
        prefixIcon: prefix,
        filled: true,
        fillColor: fillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: const TextStyle(fontSize: 11.0, color: Colors.redAccent),
      ),
    );

    if (labelText == null) {
      return dropdownField;
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
        dropdownField,
      ],
    );
  }
}
