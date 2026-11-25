import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';

/// Campo de texto universal con soporte para temas oscuros y claros,
/// iconos integrados, toggle de visibilidad para contraseñas y validaciones limpias.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final String? prefixText;
  final Widget? prefixIcon;
  final IconData? prefixIconData;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool isDark;
  final bool isDense;
  final bool uppercase;
  final TextAlign textAlign;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.prefixText,
    this.prefixIcon,
    this.prefixIconData,
    this.suffixIcon,
    this.isPassword = false,
    this.isDark = false,
    this.isDense = true,
    this.uppercase = false,
    this.textAlign = TextAlign.start,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.borderRadius = 10.0,
    this.contentPadding,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.isDark;

    // Colores ajustados según modo oscuro (Login) o claro (Formularios estándar)
    final Color fillColor = dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white;
    final Color textColor = dark ? Colors.white : AppTheme.textPrimary;
    final Color hintColor = dark ? Colors.white54 : AppTheme.textSecondary;
    final Color iconColor = dark ? Colors.white54 : Colors.grey.shade600;

    Widget? prefix;
    if (widget.prefixIcon != null) {
      prefix = widget.prefixIcon;
    } else if (widget.prefixIconData != null) {
      prefix = Icon(widget.prefixIconData, color: iconColor, size: 20);
    }

    Widget? suffix;
    if (widget.isPassword) {
      suffix = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: iconColor,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else if (widget.suffixIcon != null) {
      suffix = widget.suffixIcon;
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: dark
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 1.0),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: const BorderSide(color: AppTheme.accentColor, width: 1.5),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
    );

    final effectiveFormatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.uppercase) const _UpperCaseTextFormatter(),
    ];

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      obscureText: _obscureText,
      textAlign: widget.textAlign,
      textCapitalization: widget.uppercase
          ? TextCapitalization.characters
          : TextCapitalization.none,
      keyboardType: widget.keyboardType,
      inputFormatters:
          effectiveFormatters.isEmpty ? null : effectiveFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: TextStyle(color: textColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(color: hintColor, fontSize: 12),
        hintText: widget.hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: 12.5),
        prefixText: widget.prefixText,
        prefixStyle: TextStyle(
          color: hintColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        isDense: widget.isDense,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: const TextStyle(fontSize: 11.0, color: Colors.redAccent),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
