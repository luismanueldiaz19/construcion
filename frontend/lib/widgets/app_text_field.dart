import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';

/// Campo de texto universal con soporte para temas oscuros y claros,
/// iconos integrados, toggle de visibilidad para contraseñas y validaciones limpias.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final IconData? prefixIconData;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool isDark;
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
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.prefixIconData,
    this.suffixIcon,
    this.isPassword = false,
    this.isDark = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.borderRadius = 12.0,
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

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: widget.maxLines,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: TextStyle(color: hintColor, fontSize: 13),
        hintText: widget.hintText,
        hintStyle: TextStyle(color: hintColor, fontSize: 13),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: border,
        enabledBorder: border,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: const TextStyle(fontSize: 11.5, color: Colors.redAccent),
      ),
    );
  }
}
