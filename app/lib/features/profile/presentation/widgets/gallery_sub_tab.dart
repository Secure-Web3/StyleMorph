import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

class GallerySubTab extends ConsumerStatefulWidget {
  const GallerySubTab({super.key});

  @override
  ConsumerState<GallerySubTab> createState() => _GallerySubTabState();
}

class _GallerySubTabState extends ConsumerState<GallerySubTab> {
  bool _slot3Uploaded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            faIcon: FontAwesomeIcons.photoFilm,
            title: strings.galHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // 360 Video Scan Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.galScan360,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: [
                  Text(
                    strings.galUploaded,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.ok,
                    ),
                  ),
                  const SizedBox(width: 4),
                  FaIcon(FontAwesomeIcons.check, size: 10, color: colors.ok),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Video Preview Box
          AppCard(
            height: 100,
            variant: AppCardVariant.subtle,
            padding: EdgeInsetsDirectional.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          strings.galPlayToast,
                          style: const TextStyle(fontFamily: 'Vazirmatn'),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: AppRadius.rFull,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.pr,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.play,
                        size: 13,
                        color: colors.prt,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 6,
                  end: 8,
                  child: Text(
                    '360_scan_sara.mp4 (12MB)',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10,
                      color: colors.mu,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Base Photo Slots Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.galBasePhotos,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.tx,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                strings.galUsedInAi,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 10,
                  color: colors.mu,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // 3-Column Base Photos Grid
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.rMd,
                      border: Border.all(color: colors.pr, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: FaIcon(
                            FontAwesomeIcons.user,
                            size: 32,
                            color: colors.mu.withValues(alpha: 0.5),
                          ),
                        ),
                        PositionedDirectional(
                          top: 6,
                          start: 6,
                          child: AppBadge(
                            variant: AppBadgeVariant.success,
                            size: AppBadgeSize.sm,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(FontAwesomeIcons.check,
                                    size: 8, color: colors.ok),
                                const SizedBox(width: 3),
                                Text(strings.galApproved),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: colors.sf.withValues(alpha: 0.9),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              strings.galFullFront,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.tx,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.rMd,
                      border: Border.all(color: colors.bd),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: FaIcon(
                            FontAwesomeIcons.userLarge,
                            size: 32,
                            color: colors.mu.withValues(alpha: 0.5),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: colors.sf.withValues(alpha: 0.9),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              strings.galSideView,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.tx,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _slot3Uploaded = !_slot3Uploaded;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _slot3Uploaded
                                ? strings.galSlotAdded
                                : strings.galSlotRemoved,
                            style: const TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: AppRadius.rMd,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.bg.withValues(alpha: 0.5),
                        borderRadius: AppRadius.rMd,
                        border: Border.all(
                          color: _slot3Uploaded ? colors.ok : colors.bd,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            _slot3Uploaded
                                ? FontAwesomeIcons.check
                                : FontAwesomeIcons.plus,
                            size: 16,
                            color: _slot3Uploaded ? colors.ok : colors.mu,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _slot3Uploaded
                                ? strings.galRecorded
                                : strings.galUploadSlot3,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _slot3Uploaded ? colors.ok : colors.mu,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tip Box
          AppCard(
            backgroundColor: colors.inb.withValues(alpha: 0.4),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.circleInfo,
                    size: 14, color: colors.inColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.galTip,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: colors.tx,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
