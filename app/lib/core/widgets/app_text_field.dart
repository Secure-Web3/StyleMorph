import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final Widget? labelTrailing;
  final String? placeholder;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? suffixText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? errorText;

  const AppTextField({
    super.key,
    this.label,
    this.labelTrailing,
    this.placeholder,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.suffixText,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inputLabel(color: colors.tx),
                ),
              ),
              if (labelTrailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                labelTrailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofocus: autofocus,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            color: colors.tx,
          ),
          decoration: InputDecoration(
            isDense: true,
            counterText: maxLength != null ? '' : null,
            hintText: placeholder,
            hintStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: colors.mu,
            ),
            prefixIcon: prefix,
            suffixIcon: suffix,
            suffixText: suffixText,
            suffixStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: colors.mu,
            ),
            errorText: errorText,
            errorStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              color: colors.orColor,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.rLg,
              borderSide: BorderSide(color: colors.orColor, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.rLg,
              borderSide: BorderSide(color: colors.orColor, width: 1.5),
            ),
            filled: true,
            fillColor: colors.bg,
            constraints: maxLines == 1
                ? const BoxConstraints(minHeight: 40)
                : null,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rLg,
              borderSide: BorderSide(color: colors.bd, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rLg,
              borderSide: BorderSide(color: colors.pr, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.rLg,
              borderSide: BorderSide(color: colors.bd, width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}

/// Standardized search bar matching `AppTextField` and `AppIconButton` height (`38px`)
/// and radius (`10px`).
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          color: colors.tx,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            color: colors.mu,
          ),
          prefixIcon: Icon(Icons.search_rounded, size: 17, color: colors.mu),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          filled: true,
          fillColor: colors.bg,
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: 9,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.rLg,
            borderSide: BorderSide(color: colors.bd, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.rLg,
            borderSide: BorderSide(color: colors.pr, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.rLg,
            borderSide: BorderSide(color: colors.bd, width: 1.0),
          ),
        ),
      ),
    );
  }
}
