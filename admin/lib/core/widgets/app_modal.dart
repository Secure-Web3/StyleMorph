import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppModal {
  AppModal._();

  static Future<T?> showSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 430),
      builder: (_) => child,
    );
  }

  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    final colors = context.colors;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => Dialog(
        backgroundColor: colors.sf,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rCard,
          side: BorderSide(color: colors.bd),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
          child: child,
        ),
      ),
    );
  }
}

/// Standardized bottom sheet shell enforcing unified `20px` top corners,
/// drag handle, header bar (Title + optional trailing actions + Close `X` button),
/// `1px` divider, and consistent bottom action bar padding across all modules.
class AppBottomSheetShell extends StatelessWidget {
  final String title;
  final Widget? titleLeading;
  final List<Widget>? headerActions;
  final Widget child;
  final Widget? bottomBar;
  final double maxHeightFactor;
  final bool scrollable;
  final EdgeInsetsDirectional? contentPadding;

  const AppBottomSheetShell({
    super.key,
    required this.title,
    this.titleLeading,
    this.headerActions,
    required this.child,
    this.bottomBar,
    this.maxHeightFactor = 0.88,
    this.scrollable = true,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        borderRadius: AppRadius.rSheetTop,
        border: Border(
          top: BorderSide(color: colors.bd, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Standardized Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: colors.bd,
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),

              // Standardized Header Bar (Title + optional actions + Close X)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (titleLeading != null) ...[
                      titleLeading!,
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.moduleTitle(color: colors.tx),
                      ),
                    ),
                    ...?headerActions,
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.mu,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, thickness: 1, color: colors.bd),

              // Body
              Flexible(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: contentPadding ??
                            const EdgeInsetsDirectional.all(AppSpacing.lg),
                        child: child,
                      )
                    : Padding(
                        padding: contentPadding ??
                            const EdgeInsetsDirectional.all(AppSpacing.lg),
                        child: child,
                      ),
              ),

              // Standardized Sticky Bottom Action Bar
                    if (bottomBar != null)
                      Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: colors.sf,
                    border: Border(
                      top: BorderSide(color: colors.bd, width: 1.0),
                    ),
                  ),
                  child: bottomBar!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
