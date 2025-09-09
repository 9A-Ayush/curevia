import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';

/// Custom text field widget with consistent styling
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final TextAlign? textAlign;
  final TextStyle? style;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
    this.textAlign,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          textAlign: textAlign ?? TextAlign.start,
          style:
              style ??
              theme.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? ThemeUtils.getTextPrimaryColor(context)
                    : ThemeUtils.getTextSecondaryColor(context),
              ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: ThemeUtils.getTextSecondaryColor(context),
                    size: 20,
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor:
                fillColor ??
                (enabled
                    ? ThemeUtils.getSurfaceVariantColor(context)
                    : ThemeUtils.getDisabledBackgroundColor(context)),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getPrimaryColor(context),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              borderSide: BorderSide(color: ThemeUtils.getErrorColor(context)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getErrorColor(context),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getDisabledColor(context),
              ),
            ),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextHintColor(context),
            ),
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            errorStyle: theme.textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getErrorColor(context),
            ),
            counterStyle: theme.textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom search text field
class CustomSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool showClearButton;

  const CustomSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: Icons.search,
      suffixIcon: showClearButton && controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}

/// Custom dropdown field
class CustomDropdownField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool enabled;

  const CustomDropdownField({
    super.key,
    this.value,
    required this.items,
    this.onChanged,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: ThemeUtils.getTextSecondaryColor(context),
                    size: 20,
                  )
                : null,
            filled: true,
            fillColor: enabled
                ? ThemeUtils.getSurfaceVariantColor(context)
                : ThemeUtils.getDisabledBackgroundColor(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getPrimaryColor(context),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ThemeUtils.getErrorColor(context)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ThemeUtils.getDisabledColor(context),
              ),
            ),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: enabled
                ? ThemeUtils.getTextPrimaryColor(context)
                : ThemeUtils.getTextSecondaryColor(context),
          ),
          dropdownColor: ThemeUtils.getSurfaceColor(context),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}
