import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';

class AuthTopBar extends ConsumerWidget {
  final bool isTransparent;

  const AuthTopBar({
    super.key,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentLang = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : colors.bg,
        border: isTransparent
            ? null
            : Border(
                bottom: BorderSide(color: colors.bd.withValues(alpha: 0.5)),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Language selector dropdown
          _LanguageSelector(currentLang: currentLang, isTransparent: isTransparent),
          const SizedBox(width: AppSpacing.sm),

          // Theme palette cycle button
          _TopBarIconButton(
            onTap: () => ref.read(themeProvider.notifier).cyclePalette(),
            tooltip: 'Palette',
            isTransparent: isTransparent,
            child: FaIcon(
              FontAwesomeIcons.palette,
              size: 13,
              color: isTransparent ? Colors.white : colors.tx,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Dark/light toggle button
          _TopBarIconButton(
            onTap: () => ref.read(themeProvider.notifier).toggleDark(),
            tooltip: 'Dark / Light',
            isTransparent: isTransparent,
            child: FaIcon(
              FontAwesomeIcons.circleHalfStroke,
              size: 13,
              color: isTransparent ? Colors.white : colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String tooltip;
  final bool isTransparent;

  const _TopBarIconButton({
    required this.onTap,
    required this.child,
    required this.tooltip,
    required this.isTransparent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = isTransparent ? Colors.black.withValues(alpha: 0.45) : colors.sf;
    final border = isTransparent
        ? Colors.white.withValues(alpha: 0.25)
        : colors.bd;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rFull,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  final AppLanguage currentLang;
  final bool isTransparent;

  const _LanguageSelector({
    required this.currentLang,
    required this.isTransparent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeState = ref.watch(themeProvider);
    final bg = isTransparent ? Colors.black.withValues(alpha: 0.45) : colors.sf;
    final border = isTransparent
        ? Colors.white.withValues(alpha: 0.25)
        : colors.bd;
    final buttonTextColor = isTransparent ? Colors.white : colors.tx;

    // Dropdown menu background must always have high contrast with text.
    // In dark mode: use a crisp dark surface with light text.
    // In light mode: use a crisp white surface with dark text.
    final isDark = themeState.resolveIsDark(context);
    final dropdownBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dropdownTextColor =
        isDark ? const Color(0xFFF2F2F2) : const Color(0xFF171717);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLang.code,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 16,
            color: isTransparent ? Colors.white70 : colors.mu,
          ),
          dropdownColor: dropdownBg,
          selectedItemBuilder: (BuildContext context) {
            return AppLanguage.supportedLanguages.map((l) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l.nativeName,
                  style: AppTypography.inputLabel(
                    color: buttonTextColor,
                  ),
                ),
              );
            }).toList();
          },
          items: AppLanguage.supportedLanguages.map((l) {
            return DropdownMenuItem<String>(
              value: l.code,
              child: Text(
                l.nativeName,
                style: AppTypography.inputLabel(
                  color: dropdownTextColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (code) {
            if (code != null) {
              ref.read(localeProvider.notifier).setLanguage(code);
            }
          },
        ),
      ),
    );
  }
}
