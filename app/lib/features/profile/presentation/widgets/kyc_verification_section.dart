import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ai_review_badge.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_media_image.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/email_verification_gate.dart';
import '../../../auth/presentation/email_verification_provider.dart';
import '../../domain/kyc_model.dart';
import '../profile_providers.dart';
import 'kyc_image_preview_dialog.dart';

class KycVerificationSection extends ConsumerStatefulWidget {
  const KycVerificationSection({super.key});

  @override
  ConsumerState<KycVerificationSection> createState() =>
      _KycVerificationSectionState();
}

class _KycVerificationSectionState
    extends ConsumerState<KycVerificationSection> {
  final ImagePicker _picker = ImagePicker();

  bool _isEditing = false;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  KycDocType _selectedDocType = KycDocType.nationalId;
  XFile? _frontFile;
  XFile? _backFile;
  AiVerificationStatus? _aiStatus;
  List<AiVerificationIssueCode> _aiIssues = const [];

  @override
  void initState() {
    super.initState();
    final kycData = ref.read(appStateProvider).kycData;
    _selectedDocType = kycData.docType;
  }

  String _getDocTypeName(AppStrings strings, KycDocType docType) {
    switch (docType) {
      case KycDocType.passport:
        return strings.kycDocPassport;
      case KycDocType.driversLicense:
        return strings.kycDocDriversLicense;
      case KycDocType.nationalId:
        return strings.kycDocNationalId;
    }
  }

  String _getTile1Label(AppStrings strings) {
    switch (_selectedDocType) {
      case KycDocType.passport:
        return strings.kycDocTilePassportFront;
      case KycDocType.driversLicense:
        return strings.kycDocTileDriversLicenseFront;
      case KycDocType.nationalId:
        return strings.kycDocTileNationalIdFront;
    }
  }

  String _getTile2Label(AppStrings strings) {
    switch (_selectedDocType) {
      case KycDocType.passport:
        return strings.kycDocTilePassportBack;
      case KycDocType.driversLicense:
        return strings.kycDocTileDriversLicenseBack;
      case KycDocType.nationalId:
        return strings.kycDocTileNationalIdBack;
    }
  }

  bool get _isTile2Required => _selectedDocType != KycDocType.passport;

  bool _isSubmitReady(KycData kycData) {
    final hasFront =
        _frontFile != null || (_isEditing && kycData.frontUrl.isNotEmpty);
    if (!hasFront) return false;
    if (_isTile2Required) {
      final hasBack =
          _backFile != null ||
          (_isEditing && (kycData.backUrl?.isNotEmpty ?? false));
      if (!hasBack) return false;
    }
    return true;
  }

  Future<void> _pickImage(bool isFront, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 65,
      );
      if (picked != null) {
        setState(() {
          _aiStatus = AiVerificationStatus.reviewing;
          _aiIssues = const [];
        });

        final bytes = await picked.readAsBytes();
        final slotContext =
            '${_selectedDocType.name}_${isFront ? 'front' : 'back'}';
        final result = await ref
            .read(aiVerificationServiceProvider)
            .verifyKycDocument(
              bytes: bytes,
              fileNameOrMime: picked.mimeType ?? picked.name,
              docType: slotContext,
            );

        if (!mounted) return;
        final reason = result.issues.isNotEmpty
            ? AiReviewBadge.localizeIssue(context.strings, result.issues.first)
            : null;

        if (result.isRejected) {
          // Abort immediately: never clear or overwrite existing valid KYC files.
          setState(() {
            _aiStatus = result.status;
            _aiIssues = result.issues;
          });
          AppFeedback.showError(
            context,
            reason ?? context.strings.aiStatusRejected,
          );
        } else {
          setState(() {
            if (isFront) {
              _frontFile = picked;
            } else {
              _backFile = picked;
            }
            _aiStatus = result.status;
            _aiIssues = result.issues;
          });
        }

        if (result.isApproved || result.isRejected) {
          String uid = 'test_user';
          String? email;
          try {
            if (Firebase.apps.isNotEmpty) {
              final user = FirebaseAuth.instance.currentUser;
              uid = user?.uid ?? 'test_user';
              email = user?.email;
            }
          } catch (_) {}

          ref
              .read(notificationServiceProvider)
              .notifyKycStatus(
                uid: uid,
                approved: result.isApproved,
                reason: reason,
                recipientEmail: email,
              )
              .catchError((_) {});
        }
      }
    } catch (e) {
      debugPrint('[KycVerificationSection] pickImage error: $e');
    }
  }

  void _showImageSourceSheet(bool isFront) {
    if (!EmailVerificationGate.checkVerified(context, ref)) return;
    final strings = context.strings;
    final colors = context.colors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.sf,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.camera, color: colors.pr),
                  title: Text(strings.kycTakeCamera),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(isFront, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: FaIcon(FontAwesomeIcons.images, color: colors.pr),
                  title: Text(strings.kycChooseGallery),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(isFront, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!EmailVerificationGate.checkVerified(context, ref)) return;
    final strings = context.strings;
    final kycData = ref.read(appStateProvider).kycData;

    final hasFront =
        _frontFile != null || (_isEditing && kycData.frontUrl.isNotEmpty);
    if (!hasFront) {
      AppFeedback.showError(context, strings.kycFrontRequired);
      return;
    }

    if (_isTile2Required) {
      final hasBack =
          _backFile != null ||
          (_isEditing && (kycData.backUrl?.isNotEmpty ?? false));
      if (!hasBack) {
        AppFeedback.showError(context, strings.kycFrontRequired);
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      String uid = 'test_user';
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
        }
      } catch (_) {}

      final kycService = ref.read(kycServiceProvider);

      String frontUrl = kycData.frontUrl;
      if (_frontFile != null) {
        frontUrl = await kycService.uploadKycImage(
          uid: uid,
          file: _frontFile!,
          tag: 'front',
        );
      }

      String? backUrl = kycData.backUrl;
      if (_backFile != null) {
        backUrl = await kycService.uploadKycImage(
          uid: uid,
          file: _backFile!,
          tag: 'back',
        );
      }

      final submittedKyc = await kycService.submitKyc(
        uid: uid,
        docType: _selectedDocType,
        frontUrl: frontUrl,
        backUrl: backUrl,
      );

      ref.read(appStateProvider.notifier).updateKycData(submittedKyc);

      setState(() {
        _isEditing = false;
        _frontFile = null;
        _backFile = null;
      });

      if (mounted) {
        AppFeedback.showSuccess(context, strings.kycSubmitSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!EmailVerificationGate.checkVerified(context, ref)) return;
    final strings = context.strings;
    final kycData = ref.read(appStateProvider).kycData;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.sf,
          title: Text(strings.kycDeleteConfirmTitle),
          content: Text(strings.kycDeleteConfirmDesc),
          actions: [
            AppButton(
              size: AppButtonSize.sm,
              variant: AppButtonVariant.ghost,
              text: strings.dialogCancel,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            AppButton(
              size: AppButtonSize.sm,
              variant: AppButtonVariant.destructive,
              text: strings.kycDelete,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      String uid = 'test_user';
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? 'test_user';
        }
      } catch (_) {}

      await ref
          .read(kycServiceProvider)
          .deleteKyc(uid, frontUrl: kycData.frontUrl, backUrl: kycData.backUrl);

      ref.read(appStateProvider.notifier).updateKycData(const KycData());

      setState(() {
        _isEditing = false;
        _frontFile = null;
        _backFile = null;
      });

      if (mounted) {
        AppFeedback.showSuccess(context, strings.kycDeleteSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final kycData = appState.kycData;

    final bool showActiveCard = kycData.isSubmitted && !_isEditing;

    return AppCard(
      variant: AppCardVariant.subtle,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Title & Live Status Badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppSectionHeader(
                faIcon: FontAwesomeIcons.idCardClip,
                title: strings.kycSectionTitle,
              ),
              _buildStatusBadge(colors, strings, kycData.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.kycSectionSubtitle,
            style: AppTypography.caption(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_aiStatus != null) ...[
            AiReviewBadge(status: _aiStatus!, issues: _aiIssues),
            const SizedBox(height: AppSpacing.md),
          ],

          // Rejection Reason Box (if rejected)
          if (kycData.isRejected &&
              (kycData.rejectionReason?.isNotEmpty ?? false)) ...[
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.wnb,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: colors.wn.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 14,
                    color: colors.wn,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.kycRejectionReasonLabel,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.wn,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kycData.rejectionReason!,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: colors.tx,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Email Verification Lock Notice for Unverified Users
          if (!ref.watch(emailVerificationProvider).isVerified) ...[
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.wnb,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: colors.wn.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.lock, size: 13, color: colors.wn),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      strings.kycEmailVerificationRequiredHint,
                      style: AppTypography.caption(color: colors.tx),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Active Document Display vs Upload / Edit Form
          if (showActiveCard)
            _buildSubmittedCard(colors, strings, kycData)
          else
            _buildUploadForm(colors, strings, kycData),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    AppColors colors,
    AppStrings strings,
    KycStatus status,
  ) {
    switch (status) {
      case KycStatus.verified:
        return AppBadge(
          variant: AppBadgeVariant.success,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.circleCheck, size: 10),
              const SizedBox(width: AppSpacing.xs),
              Text(strings.kycStatusVerified),
            ],
          ),
        );
      case KycStatus.pending:
        return AppBadge(
          variant: AppBadgeVariant.warning,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.clock, size: 10),
              const SizedBox(width: AppSpacing.xs),
              Text(strings.kycStatusPending),
            ],
          ),
        );
      case KycStatus.rejected:
        return AppBadge(
          variant: AppBadgeVariant.destructive,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.circleXmark, size: 10),
              const SizedBox(width: AppSpacing.xs),
              Text(strings.kycStatusRejected),
            ],
          ),
        );
      case KycStatus.notSubmitted:
        return AppBadge(
          variant: AppBadgeVariant.standard,
          child: Text(strings.kycStatusNotSubmitted),
        );
    }
  }

  Widget _buildSubmittedCard(
    AppColors colors,
    AppStrings strings,
    KycData kycData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Document Meta Information
        Container(
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.sf,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: colors.bd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDocTypeName(strings, kycData.docType),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                  if (kycData.isVerified)
                    FaIcon(
                      FontAwesomeIcons.circleCheck,
                      size: 14,
                      color: colors.ok,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Image Thumbnails Row with Full-Screen Preview Action
              Row(
                children: [
                  // Front Image Thumbnail
                  Expanded(
                    child: _buildImageThumbnail(
                      title: strings.kycUploadFront,
                      imageUrl: kycData.frontUrl,
                      colors: colors,
                      strings: strings,
                    ),
                  ),
                  if (kycData.backUrl?.isNotEmpty ?? false) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildImageThumbnail(
                        title: strings.kycUploadBack,
                        imageUrl: kycData.backUrl,
                        colors: colors,
                        strings: strings,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // CRUD Actions: Edit / Replace & Delete
        Row(
          children: [
            Expanded(
              child: AppButton(
                size: AppButtonSize.sm,
                variant: AppButtonVariant.outline,
                icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 11),
                text: strings.kycEdit,
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              size: AppButtonSize.sm,
              variant: AppButtonVariant.destructive,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const FaIcon(FontAwesomeIcons.trashCan, size: 11),
              text: strings.kycDelete,
              onPressed: _isDeleting ? null : _handleDelete,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    required String title,
    required String? imageUrl,
    required AppColors colors,
    required AppStrings strings,
  }) {
    return InkWell(
      onTap: () {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          KycImagePreviewDialog.show(context, imageUrl: imageUrl, title: title);
        }
      },
      borderRadius: AppRadius.rMd,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: colors.bd),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              AppMediaImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: FaIcon(
                    FontAwesomeIcons.idCard,
                    size: 28,
                    color: colors.mu,
                  ),
                ),
              )
            else
              Center(
                child: FaIcon(
                  FontAwesomeIcons.idCard,
                  size: 28,
                  color: colors.mu,
                ),
              ),
            PositionedDirectional(
              bottom: 4,
              end: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: AppRadius.rSm,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.magnifyingGlassPlus,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm(
    AppColors colors,
    AppStrings strings,
    KycData kycData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Document Type Selection Segment
        Text(
          strings.kycSelectDocType,
          style: AppTypography.inputLabel(color: colors.tx),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: KycDocType.values.map((type) {
            final isSelected = _selectedDocType == type;
            return AppButton(
              size: AppButtonSize.sm,
              isFullWidth: false,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              variant: isSelected
                  ? AppButtonVariant.primary
                  : AppButtonVariant.outline,
              text: _getDocTypeName(strings, type),
              onPressed: () {
                if (_selectedDocType != type) {
                  setState(() {
                    _selectedDocType = type;
                    _frontFile = null;
                    _backFile = null;
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),

        // Front & Back Upload Boxes
        Row(
          children: [
            // Front Image Slot (Required)
            Expanded(
              child: _buildUploadBox(
                label: _getTile1Label(strings),
                file: _frontFile,
                existingUrl: kycData.frontUrl,
                isRequired: true,
                isFront: true,
                colors: colors,
                strings: strings,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Back/Selfie Image Slot
            Expanded(
              child: _buildUploadBox(
                label: _getTile2Label(strings),
                file: _backFile,
                existingUrl: kycData.backUrl,
                isRequired: _isTile2Required,
                isFront: false,
                colors: colors,
                strings: strings,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Action Buttons: Submit & (if editing) Cancel
        Row(
          children: [
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.primary,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.prt,
                        ),
                      )
                    : const FaIcon(FontAwesomeIcons.cloudArrowUp, size: 12),
                text: _isSubmitting ? strings.kycSubmitting : strings.kycSubmit,
                onPressed: (_isSubmitting || !_isSubmitReady(kycData))
                    ? null
                    : _handleSubmit,
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                variant: AppButtonVariant.ghost,
                text: strings.dialogCancel,
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _frontFile = null;
                    _backFile = null;
                  });
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String label,
    required XFile? file,
    required String? existingUrl,
    required bool isRequired,
    required bool isFront,
    required AppColors colors,
    required AppStrings strings,
  }) {
    final hasImage = file != null || (existingUrl?.isNotEmpty ?? false);

    return InkWell(
      onTap: () => _showImageSourceSheet(isFront),
      borderRadius: AppRadius.rMd,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: hasImage ? colors.ok : colors.bd,
            width: hasImage ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (file != null)
              if (kIsWeb)
                Image.network(file.path, fit: BoxFit.cover)
              else
                Image.file(File(file.path), fit: BoxFit.cover)
            else if (existingUrl != null && existingUrl.isNotEmpty)
              AppMediaImage(
                existingUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: FaIcon(
                    FontAwesomeIcons.idCard,
                    size: 24,
                    color: colors.mu,
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.cloudArrowUp,
                      size: 20,
                      color: colors.mu,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          color: colors.mu,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Top Status & Remove Pill
            if (hasImage) ...[
              PositionedDirectional(
                top: 4,
                end: 4,
                child: AiReviewBadge(
                  status: _aiStatus ?? AiVerificationStatus.pendingAi,
                  compact: true,
                ),
              ),
              PositionedDirectional(
                top: 4,
                start: 4,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isFront) {
                        _frontFile = null;
                      } else {
                        _backFile = null;
                      }
                    });
                  },
                  borderRadius: AppRadius.rSm,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            if (file != null)
              PositionedDirectional(
                bottom: 4,
                start: 4,
                end: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: AppRadius.rSm,
                  ),
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
