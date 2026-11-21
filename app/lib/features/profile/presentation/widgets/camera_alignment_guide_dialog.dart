import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class CameraAlignmentGuideDialog extends StatelessWidget {
  final String slotKey;
  final String slotTitle;

  const CameraAlignmentGuideDialog({
    super.key,
    required this.slotKey,
    required this.slotTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String slotKey,
    required String slotTitle,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) =>
          CameraAlignmentGuideDialog(slotKey: slotKey, slotTitle: slotTitle),
    );
  }

  FaIconData _getSlotIcon() {
    switch (slotKey) {
      case 'front_face':
        return FontAwesomeIcons.solidUser;
      case 'side_face':
        return FontAwesomeIcons.user;
      case 'body_front':
        return FontAwesomeIcons.person;
      case 'body_side':
        return FontAwesomeIcons.personWalking;
      case 'body_back':
        return FontAwesomeIcons.personBooth;
      case 'hand_skin':
        return FontAwesomeIcons.hand;
      case 'scan_360':
        return FontAwesomeIcons.video;
      default:
        return FontAwesomeIcons.camera;
    }
  }

  List<String> _getGuidancePoints(BuildContext context) {
    final strings = context.strings;
    switch (slotKey) {
      case 'front_face':
        return [
          strings.galGuideFrontFace1,
          strings.galGuideFrontFace2,
          strings.galGuideFrontFace3,
        ];
      case 'side_face':
        return [
          strings.galGuideSideFace1,
          strings.galGuideSideFace2,
          strings.galGuideSideFace3,
        ];
      case 'body_front':
        return [
          strings.galGuideBodyFront1,
          strings.galGuideBodyFront2,
          strings.galGuideBodyFront3,
        ];
      case 'body_side':
        return [
          strings.galGuideBodySide1,
          strings.galGuideBodySide2,
          strings.galGuideBodySide3,
        ];
      case 'body_back':
        return [
          strings.galGuideBodyBack1,
          strings.galGuideBodyBack2,
          strings.galGuideBodyBack3,
        ];
      case 'hand_skin':
        return [
          strings.galGuideHandSkin1,
          strings.galGuideHandSkin2,
          strings.galGuideHandSkin3,
        ];
      case 'scan_360':
      default:
        return [
          strings.galGuideScan3601,
          strings.galGuideScan3602,
          strings.galGuideScan3603,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final points = _getGuidancePoints(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: colors.sf,
          borderRadius: AppRadius.rXl,
          border: Border.all(color: colors.bd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.sm,
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      strings.galAlignmentGuideTitle,
                      style: AppTypography.titleMedium(color: colors.tx),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Silhouette preview area
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.rLg,
                      border: Border.all(
                        color: colors.pr.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle grid/crosshair lines
                        CustomPaint(
                          size: const Size(double.infinity, 140),
                          painter: _CrosshairPainter(color: colors.bd),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colors.pr.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.pr.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Center(
                                child: FaIcon(
                                  _getSlotIcon(),
                                  size: 28,
                                  color: colors.pr,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              slotTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.tx,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Guidance checklist items
                  ...points.map(
                    (pt) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: FaIcon(
                              FontAwesomeIcons.circleCheck,
                              size: 13,
                              color: colors.ok,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              pt,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                height: 1.45,
                                color: colors.tx,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: strings.galReadyToCapture,
                      icon: const FaIcon(FontAwesomeIcons.camera, size: 14),
                      variant: AppButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Center vertical and horizontal dashed guides
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
