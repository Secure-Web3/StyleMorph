import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Standard square icon action button (`38x38`, `1px` border, `10px` radius).
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final int badgeCount;
  final String? tooltip;
  final Color? iconColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.badgeCount = 0,
    this.tooltip,
    this.iconColor,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = iconColor ?? (isActive ? colors.pr : colors.tx);

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isActive
                ? colors.pr.withValues(alpha: 0.1)
                : colors.bg,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: isActive ? colors.pr : colors.bd,
              width: 1.0,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: fg,
            ),
          ),
        ),
      ),
    );

    if (badgeCount > 0) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          PositionedDirectional(
            top: -4,
            end: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: colors.orColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.sf, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors.prt,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
