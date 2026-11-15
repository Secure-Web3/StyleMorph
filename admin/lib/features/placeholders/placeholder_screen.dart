import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_badge.dart';

class PlaceholderSectionScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String partTwoDescription;

  const PlaceholderSectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.partTwoDescription,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.pr.withValues(alpha: 0.08),
                  borderRadius: AppRadius.rXxl,
                  border: Border.all(color: colors.bd),
                ),
                child: Icon(icon, color: colors.pr, size: 36),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.tx,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  color: colors.mu,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppCard(
                padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.architecture, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'برنامه‌ریزی فاز اجرایی',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.bold,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                        const AppBadge(
                          variant: AppBadgeVariant.info,
                          child: Text('برنامه‌ریزی شده در پارت ۲'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      partTwoDescription,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        height: 1.6,
                        color: colors.tx.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
