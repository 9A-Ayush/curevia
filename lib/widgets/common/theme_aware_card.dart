import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

/// A card widget that automatically adapts to the current theme
class ThemeAwareCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const ThemeAwareCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final defaultPadding = padding ?? const EdgeInsets.all(16);
    final defaultMargin = margin ?? const EdgeInsets.all(8);

    Widget cardContent = Container(
      padding: defaultPadding,
      margin: defaultMargin,
      decoration: BoxDecoration(
        color: backgroundColor ?? ThemeUtils.getSurfaceColor(context),
        borderRadius: defaultBorderRadius,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: elevation ?? 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultBorderRadius,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// A container widget that automatically adapts to the current theme
class ThemeAwareContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const ThemeAwareContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        color: backgroundColor ?? ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border ?? Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: child,
    );
  }
}

/// A text widget that automatically adapts to the current theme
class ThemeAwareText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isPrimary;
  final bool isSecondary;
  final bool isHint;

  const ThemeAwareText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isPrimary = true,
    this.isSecondary = false,
    this.isHint = false,
  });

  const ThemeAwareText.secondary(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : isPrimary = false,
       isSecondary = true,
       isHint = false;

  const ThemeAwareText.hint(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : isPrimary = false,
       isSecondary = false,
       isHint = true;

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isHint) {
      textColor = ThemeUtils.getTextHintColor(context);
    } else if (isSecondary) {
      textColor = ThemeUtils.getTextSecondaryColor(context);
    } else {
      textColor = ThemeUtils.getTextPrimaryColor(context);
    }

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: textColor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// An icon widget that automatically adapts to the current theme
class ThemeAwareIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool isPrimary;
  final bool isSecondary;

  const ThemeAwareIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.isPrimary = false,
    this.isSecondary = true,
  });

  const ThemeAwareIcon.primary(
    this.icon, {
    super.key,
    this.size,
    this.color,
  }) : isPrimary = true,
       isSecondary = false;

  const ThemeAwareIcon.secondary(
    this.icon, {
    super.key,
    this.size,
    this.color,
  }) : isPrimary = false,
       isSecondary = true;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    if (color != null) {
      iconColor = color!;
    } else if (isPrimary) {
      iconColor = ThemeUtils.getPrimaryColor(context);
    } else {
      iconColor = ThemeUtils.getIconColor(context);
    }

    return Icon(
      icon,
      size: size,
      color: iconColor,
    );
  }
}

/// A divider widget that automatically adapts to the current theme
class ThemeAwareDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;

  const ThemeAwareDivider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: ThemeUtils.getDividerColor(context),
    );
  }
}

/// A circular avatar that automatically adapts to the current theme
class ThemeAwareCircleAvatar extends StatelessWidget {
  final Widget? child;
  final ImageProvider? backgroundImage;
  final double? radius;
  final Color? backgroundColor;

  const ThemeAwareCircleAvatar({
    super.key,
    this.child,
    this.backgroundImage,
    this.radius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
      backgroundImage: backgroundImage,
      child: child,
    );
  }
}
