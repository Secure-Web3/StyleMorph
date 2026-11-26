import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/ai/ai_verification_models.dart';
import '../../../../core/ai/ai_verification_service.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ai_review_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_media_image.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/email_verification_gate.dart';
import '../profile_providers.dart';
import 'camera_alignment_guide_dialog.dart';
import 'kyc_image_preview_dialog.dart';

class MediaSubTab extends ConsumerStatefulWidget {
  const MediaSubTab({super.key});

  @override
  ConsumerState<MediaSubTab> createState() => _MediaSubTabState();
}

class _MediaSlotDef {
  final String key;
  final String title;
  final bool isRequired;
  final bool isVideo;
  final FaIconData icon;

  const _MediaSlotDef({
    required this.key,
    required this.title,
    required this.isRequired,
    this.isVideo = false,
    required this.icon,
  });
}

class _MediaSubTabState extends ConsumerState<MediaSubTab> {
  final ImagePicker _picker = ImagePicker();
  String? _uploadingSlot;
  final Map<String, AiVerificationResult> _slotAiResults = {};
  final Set<String> _reviewingSlots = {};

  List<_MediaSlotDef> _getSlots(BuildContext context, String personaMode) {
    final strings = context.strings;

    if (personaMode == 'privacy_avatar') {
      return [
        _MediaSlotDef(
          key: 'front_face',
          title: strings.galSlotFrontFace,
          isRequired: true,
          icon: FontAwesomeIcons.solidUser,
        ),
        _MediaSlotDef(
          key: 'side_face',
          title: strings.galSlotSideFace,
          isRequired: true,
          icon: FontAwesomeIcons.user,
        ),
      ];
    }

    // full_body mode: all 7 reference slots
    return [
      _MediaSlotDef(
        key: 'front_face',
        title: strings.galSlotFrontFace,
        isRequired: true,
        icon: FontAwesomeIcons.solidUser,
      ),
      _MediaSlotDef(
        key: 'side_face',
        title: strings.galSlotSideFace,
        isRequired: true,
        icon: FontAwesomeIcons.user,
      ),
      _MediaSlotDef(
        key: 'body_front',
        title: strings.galSlotBodyFront,
        isRequired: true,
        icon: FontAwesomeIcons.person,
      ),
      _MediaSlotDef(
        key: 'body_side',
        title: strings.galSlotBodySide,
        isRequired: true,
        icon: FontAwesomeIcons.personWalking,
      ),
      _MediaSlotDef(
        key: 'body_back',
        title: strings.galSlotBodyBack,
        isRequired: false,
        icon: FontAwesomeIcons.personBooth,
      ),
      _MediaSlotDef(
        key: 'hand_skin',
        title: strings.galSlotHandSkin,
        isRequired: false,
        icon: FontAwesomeIcons.hand,
      ),
      _MediaSlotDef(
        key: 'scan_360',
        title: strings.galSlotScan360,
        isRequired: false,
        isVideo: true,
        icon: FontAwesomeIcons.video,
      ),
    ];
  }

  Future<void> _handleUpload(
    BuildContext context,
    _MediaSlotDef slot, {
    required ImageSource source,
  }) async {
    if (!EmailVerificationGate.checkVerified(context, ref)) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
    final mediaService = ref.read(mediaServiceProvider);
    final strings = context.strings;

    try {
      XFile? picked;
      if (slot.isVideo) {
        picked = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );
      } else {
        picked = await _picker.pickImage(
          source: source,
          imageQuality: 65,
          maxWidth: 720,
          maxHeight: 720,
        );
      }

      if (picked == null) return;

      if (mounted) {
        setState(() {
          _uploadingSlot = slot.key;
          _reviewingSlots.add(slot.key);
        });
      }

      final bytes = await picked.readAsBytes();
      final aiResult = await ref
          .read(aiVerificationServiceProvider)
          .verifyProfileMedia(
            bytes: bytes,
            fileNameOrMime: picked.mimeType ?? picked.name,
            slotKey: slot.key,
            isVideo: slot.isVideo,
          );

      if (mounted) {
        setState(() {
          _reviewingSlots.remove(slot.key);
          _slotAiResults[slot.key] = aiResult;
        });
      }

      final reason = aiResult.issues.isNotEmpty
          ? AiReviewBadge.localizeIssue(strings, aiResult.issues.first)
          : null;
      if (aiResult.isApproved || aiResult.isRejected) {
        ref
            .read(notificationServiceProvider)
            .notifyMediaReviewStatus(
              uid: uid,
              mediaLabel: slot.title,
              approved: aiResult.isApproved,
              reason: reason,
            )
            .catchError((_) {});
      }

      if (aiResult.isRejected) {
        // Abort immediately: preserve any existing valid media slot URL intact.
        if (context.mounted) {
          AppToast.showError(context, reason ?? strings.aiStatusRejected);
        }
        return;
      }

      final wasReplacing =
          (ref.read(appStateProvider).mediaSlots[slot.key] ?? '')
              .trim()
              .isNotEmpty;

      final downloadUrl = await mediaService.uploadMediaSlot(
        uid: uid,
        slotKey: slot.key,
        file: picked,
        isVideo: slot.isVideo,
      );

      ref
          .read(appStateProvider.notifier)
          .updateMediaSlot(slot.key, downloadUrl);

      if (!aiResult.isApproved && !aiResult.isRejected) {
        ref
            .read(notificationServiceProvider)
            .createNotification(
              uid: uid,
              title: wasReplacing
                  ? strings.notifMediaReplacedTitle
                  : strings.notifMediaUploadedTitle,
              body: slot.title,
              category: 'profile',
              targetRoute: 'profile_gallery',
              emoji: wasReplacing ? '🔄' : '📸',
              sendEmail: false,
              eventType: wasReplacing
                  ? 'media_slot_replaced'
                  : 'media_slot_uploaded',
            )
            .catchError((_) {});
      }

      if (context.mounted) {
        AppToast.showSuccess(context, '${slot.title} - ${strings.galUploaded}');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, 'Upload error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingSlot = null;
        });
      }
    }
  }

  Future<void> _pickWithCamera(BuildContext context, _MediaSlotDef slot) async {
    if (!EmailVerificationGate.checkVerified(context, ref)) return;
    final ready = await CameraAlignmentGuideDialog.show(
      context,
      slotKey: slot.key,
      slotTitle: slot.title,
    );

    if (ready == true && mounted) {
      await _handleUpload(this.context, slot, source: ImageSource.camera);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    _MediaSlotDef slot,
    String? mediaUrl,
  ) async {
    if (!EmailVerificationGate.checkVerified(context, ref)) return;
    final colors = context.colors;
    final strings = context.strings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.sf,
        title: Text(
          strings.galDeleteConfirmTitle,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
            color: colors.tx,
          ),
        ),
        content: Text(
          strings.galDeleteConfirmDesc,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            color: colors.tx,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              strings.dialogCancel,
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.mu),
            ),
          ),
          AppButton(
            text: strings.sessDelete,
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      final mediaService = ref.read(mediaServiceProvider);

      try {
        await mediaService.deleteMediaSlot(
          uid: uid,
          slotKey: slot.key,
          mediaUrl: mediaUrl,
        );
        ref.read(appStateProvider.notifier).deleteMediaSlot(slot.key);
        if (mounted) {
          setState(() {
            _slotAiResults.remove(slot.key);
          });
        }
        ref
            .read(notificationServiceProvider)
            .createNotification(
              uid: uid,
              title: strings.notifMediaDeletedTitle,
              body: slot.title,
              category: 'profile',
              targetRoute: 'profile_gallery',
              emoji: '🗑️',
              sendEmail: false,
              eventType: 'media_slot_deleted',
            )
            .catchError((_) {});
      } catch (e) {
        if (context.mounted) {
          AppToast.showError(context, 'Delete error: $e');
        }
      }
    }
  }

  void _showMediaOptionsSheet(
    BuildContext context,
    _MediaSlotDef slot,
    String? currentUrl,
  ) {
    final colors = context.colors;
    final strings = context.strings;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                slot.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colors.tx,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.pr.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.camera,
                      size: 16,
                      color: colors.pr,
                    ),
                  ),
                ),
                title: Text(
                  strings.galTakeCameraWithGuide,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    color: colors.tx,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickWithCamera(context, slot);
                },
              ),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.pr.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.images,
                      size: 16,
                      color: colors.pr,
                    ),
                  ),
                ),
                title: Text(
                  strings.galUploadFromGallery,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    color: colors.tx,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleUpload(context, slot, source: ImageSource.gallery);
                },
              ),
              if (currentUrl != null && currentUrl.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.orColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.trashCan,
                        size: 16,
                        color: colors.orColor,
                      ),
                    ),
                  ),
                  title: Text(
                    strings.sessDelete,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: colors.orColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmDelete(context, slot, currentUrl);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final personaMode = appState.personaMode;
    final mediaSlots = appState.mediaSlots;
    final slots = _getSlots(context, personaMode);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title
          AppSectionHeader(
            faIcon: FontAwesomeIcons.photoFilm,
            title: strings.galHeader,
          ),
          const SizedBox(height: AppSpacing.md),

          // 1. Dual-Persona Architecture Switcher Card
          _buildPersonaSwitcher(context, personaMode),
          const SizedBox(height: AppSpacing.lg),

          // Privacy mode info disclaimer
          if (personaMode == 'privacy_avatar') ...[
            AppCard(
              backgroundColor: colors.pr.withValues(alpha: 0.08),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.shieldHalved,
                    size: 16,
                    color: colors.pr,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      strings.galModePrivacyDesc,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        height: 1.4,
                        color: colors.tx,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 2. Reference Slots Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  personaMode == 'privacy_avatar'
                      ? strings.galModePrivacy
                      : strings.galBasePhotos,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
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
          const SizedBox(height: AppSpacing.sm),

          // 3. Grid of Reference Slots (2 columns)
          _buildSlotsGrid(context, slots, mediaSlots),
          const SizedBox(height: AppSpacing.lg),

          // 4. Luxury Editorial Tip Box
          AppCard(
            backgroundColor: colors.inb.withValues(alpha: 0.4),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 14,
                  color: colors.inColor,
                ),
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

  Widget _buildPersonaSwitcher(BuildContext context, String currentMode) {
    final colors = context.colors;
    final strings = context.strings;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      variant: AppCardVariant.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              top: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              strings.galPersonaModeTitle,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.tx,
              ),
            ),
          ),
          Row(
            children: [
              // Mode 1: Privacy Avatar
              Expanded(
                child: _buildPersonaOption(
                  context,
                  modeKey: 'privacy_avatar',
                  title: strings.galModePrivacy,
                  icon: FontAwesomeIcons.userShield,
                  isSelected: currentMode == 'privacy_avatar',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Mode 2: Full Body Persona
              Expanded(
                child: _buildPersonaOption(
                  context,
                  modeKey: 'full_body',
                  title: strings.galModeFullBody,
                  icon: FontAwesomeIcons.personRays,
                  isSelected: currentMode == 'full_body',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaOption(
    BuildContext context, {
    required String modeKey,
    required String title,
    required FaIconData icon,
    required bool isSelected,
  }) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          ref.read(appStateProvider.notifier).setPersonaMode(modeKey);
          final uid = currentAuthenticatedUid();
          if (uid != null) {
            ref
                .read(mediaServiceProvider)
                .savePersonaMode(uid: uid, mode: modeKey);
            ref
                .read(notificationServiceProvider)
                .createNotification(
                  uid: uid,
                  title: context.strings.notifPersonaModeTitle,
                  body: title,
                  category: 'profile',
                  targetRoute: 'profile_gallery',
                  emoji: '🎭',
                  sendEmail: false,
                  eventType: 'persona_mode_updated',
                )
                .catchError((_) {});
          }
        }
      },
      borderRadius: AppRadius.rMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.pr.withValues(alpha: 0.12) : colors.bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: isSelected ? colors.pr : colors.bd,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 20, color: isSelected ? colors.pr : colors.mu),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.pr : colors.tx,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsGrid(
    BuildContext context,
    List<_MediaSlotDef> slots,
    Map<String, String> mediaSlots,
  ) {
    final colors = context.colors;
    final strings = context.strings;

    final uploadedSlots = slots
        .where((s) => (mediaSlots[s.key] ?? '').trim().isNotEmpty)
        .toList();
    final emptySlots = slots
        .where((s) => (mediaSlots[s.key] ?? '').trim().isEmpty)
        .toList();
    final orderedSlots = [...uploadedSlots, ...emptySlots];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: orderedSlots.map((slot) {
            final mediaUrl = mediaSlots[slot.key];
            final isUploaded = mediaUrl != null && mediaUrl.isNotEmpty;
            final isUploading = _uploadingSlot == slot.key;

            return SizedBox(
              key: ValueKey(slot.key),
              width: cardWidth,
              child: AppCard(
                padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                variant: AppCardVariant.subtle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge row (Required / Optional / Pro + Upload status)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: slot.isRequired
                                ? colors.pr.withValues(alpha: 0.15)
                                : colors.bg,
                            borderRadius: AppRadius.rSm,
                            border: Border.all(
                              color: slot.isRequired
                                  ? colors.pr.withValues(alpha: 0.4)
                                  : colors.bd,
                            ),
                          ),
                          child: Text(
                            slot.isRequired
                                ? strings.galRequired
                                : strings.galOptional,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: slot.isRequired ? colors.pr : colors.mu,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isUploaded || _reviewingSlots.contains(slot.key))
                          Flexible(
                            child: AiReviewBadge(
                              status: _reviewingSlots.contains(slot.key)
                                  ? AiVerificationStatus.reviewing
                                  : (_slotAiResults[slot.key]?.status ??
                                        AiVerificationStatus.pendingAi),
                              issues:
                                  _slotAiResults[slot.key]?.issues ?? const [],
                              isSimulated:
                                  _slotAiResults[slot.key]?.isSimulated ??
                                  false,
                              compact: true,
                            ),
                          )
                        else
                          Flexible(
                            child: Text(
                              strings.galAwaitingUpload,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 9,
                                color: colors.mu,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Preview / Upload Area
                    AspectRatio(
                      aspectRatio: 1.1,
                      child: InkWell(
                        onTap: isUploading
                            ? null
                            : () {
                                if (isUploaded) {
                                  if (slot.isVideo) {
                                    AppToast.showInfo(
                                      context,
                                      strings.galPlayToast,
                                    );
                                  } else {
                                    KycImagePreviewDialog.show(
                                      context,
                                      imageUrl: mediaUrl,
                                      title: slot.title,
                                    );
                                  }
                                } else {
                                  _showMediaOptionsSheet(
                                    context,
                                    slot,
                                    mediaUrl,
                                  );
                                }
                              },
                        borderRadius: AppRadius.rMd,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.bg,
                            borderRadius: AppRadius.rMd,
                            border: Border.all(
                              color: isUploaded ? colors.ok : colors.bd,
                              width: isUploaded ? 1.5 : 1.0,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isUploading)
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.pr,
                                )
                              else if (isUploaded && !slot.isVideo)
                                ClipRRect(
                                  borderRadius: AppRadius.rMd,
                                  child: AppMediaImage(
                                    mediaUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: FaIcon(
                                            slot.icon,
                                            size: 28,
                                            color: colors.ok,
                                          ),
                                        ),
                                  ),
                                )
                              else if (isUploaded && slot.isVideo)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: colors.ok.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.play,
                                          size: 16,
                                          color: colors.ok,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: colors.sf,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: colors.bd),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          slot.icon,
                                          size: 16,
                                          color: colors.mu,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FaIcon(
                                      FontAwesomeIcons.plus,
                                      size: 12,
                                      color: colors.mu,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Slot title
                    Text(
                      slot.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.tx,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Actions Row
                    if (isUploaded)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Replace
                          InkWell(
                            onTap: () =>
                                _showMediaOptionsSheet(context, slot, mediaUrl),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: FaIcon(
                                FontAwesomeIcons.arrowsRotate,
                                size: 12,
                                color: colors.mu,
                              ),
                            ),
                          ),
                          // Delete
                          InkWell(
                            onTap: () =>
                                _confirmDelete(context, slot, mediaUrl),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: FaIcon(
                                FontAwesomeIcons.trashCan,
                                size: 12,
                                color: colors.orColor,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _pickWithCamera(context, slot),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.camera,
                                size: 13,
                                color: colors.pr,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _handleUpload(
                              context,
                              slot,
                              source: ImageSource.gallery,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.images,
                                size: 13,
                                color: colors.mu,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
