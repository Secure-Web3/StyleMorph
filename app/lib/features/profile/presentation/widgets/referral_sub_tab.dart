import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/referral_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/auth_provider.dart';
import 'share_actions.dart' as share_actions;

final referralsStreamProvider = StreamProvider.autoDispose
    .family<List<ReferralEntry>, String>((ref, uid) {
      if (uid.isEmpty) return const Stream.empty();
      return ref.watch(referralServiceProvider).referralsStream(uid);
    });

class ReferralSubTab extends ConsumerStatefulWidget {
  const ReferralSubTab({
    super.key,
    @visibleForTesting this.onShareLinkOverride,
    @visibleForTesting this.uidOverride,
  });

  final Future<bool> Function(String link, String title)? onShareLinkOverride;
  final String? uidOverride;

  @override
  ConsumerState<ReferralSubTab> createState() => _ReferralSubTabState();
}

class _ReferralSubTabState extends ConsumerState<ReferralSubTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      String uid = '';
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        }
      } catch (_) {}
      if (uid.isNotEmpty) {
        final referralService = ref.read(referralServiceProvider);
        final ensuredCode = await referralService.ensureUserReferralCode(uid);
        final fresh = await referralService.getReferrals(uid);
        if (mounted) {
          final currentCode = ref.read(appStateProvider).referralCode;
          if (fresh.isNotEmpty ||
              (ensuredCode.isNotEmpty && currentCode.isEmpty)) {
            ref
                .read(appStateProvider.notifier)
                .setReferralData(
                  referralCode: ensuredCode.isNotEmpty && currentCode.isEmpty
                      ? ensuredCode
                      : null,
                  referrals: fresh.isNotEmpty ? fresh : null,
                );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shareOrCopyLink(
    BuildContext context,
    String link,
    AppStrings strings,
  ) async {
    if (link.isEmpty) return;
    final shareFn = widget.onShareLinkOverride ?? share_actions.shareLink;
    final shared = await shareFn(link, 'StyleMorph');

    if (!shared) {
      Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) return;
      AppToast.showSuccess(context, strings.refCopiedToast);
    }
  }

  String _resolveEffectiveUid() {
    if (widget.uidOverride != null && widget.uidOverride!.isNotEmpty) {
      return widget.uidOverride!;
    }
    String uid = ref.read(currentUidProvider) ?? '';
    if (uid.isEmpty) {
      try {
        if (Firebase.apps.isNotEmpty) {
          uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        }
      } catch (_) {
        uid = '';
      }
    }
    return uid;
  }

  Future<void> _openEnterReferralDialog(
    BuildContext context,
    AppStrings strings,
    String uid,
  ) async {
    final inputCtrl = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    final resolvedReferrer = await AppModal.showAppDialog<UplineReferrerInfo>(
      context: context,
      barrierDismissible: true,
      child: StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final colors = dialogCtx.colors;
          return Column(
            key: const Key('ref_upline_input_dialog'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.userCheck,
                    size: 16,
                    color: colors.pr,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      strings.refEnterCodeBtn,
                      style: AppTypography.cardTitle(color: colors.tx),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('ref_upline_input_field'),
                controller: inputCtrl,
                placeholder: strings.refUplineInputHint,
                errorText: errorText,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      variant: AppButtonVariant.outline,
                      text: strings.dialogCancel,
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.of(dialogCtx).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      key: const Key('ref_upline_lookup_btn'),
                      variant: AppButtonVariant.primary,
                      text: strings.dialogConfirm,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setDialogState(() {
                                isSubmitting = true;
                                errorText = null;
                              });
                              final result = await ref
                                  .read(referralServiceProvider)
                                  .lookupReferrerByInput(
                                    rawInput: inputCtrl.text,
                                    currentUid: uid,
                                  );
                              if (!dialogCtx.mounted) return;
                              if (result.status == ReferrerLookupStatus.found &&
                                  result.referrer != null) {
                                Navigator.of(dialogCtx).pop(result.referrer);
                              } else {
                                setDialogState(() {
                                  isSubmitting = false;
                                  errorText =
                                      result.status ==
                                          ReferrerLookupStatus.selfReferral
                                      ? strings.refUplineSelfReferral
                                      : strings.refUplineInvalidCode;
                                });
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      inputCtrl.dispose();
    });
    if (resolvedReferrer == null || !mounted || !context.mounted) return;

    final confirmed = await AppModal.showAppDialog<bool>(
      context: context,
      barrierDismissible: true,
      child: Column(
        key: const Key('ref_upline_confirm_dialog'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.refUplineConfirmTitle,
            style: AppTypography.cardTitle(color: context.colors.tx),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.refUplineConfirmDesc
                .replaceAll('{name}', resolvedReferrer.displayName)
                .replaceAll('{code}', resolvedReferrer.code),
            style: AppTypography.bodySmall(color: context.colors.mu),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  text: strings.dialogCancel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  key: const Key('ref_upline_confirm_btn'),
                  variant: AppButtonVariant.primary,
                  text: strings.dialogConfirm,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || !context.mounted) return;

    final appState = ref.read(appStateProvider);
    final email = appState.identityValues['email'] ?? '';
    final name =
        appState.identityValues['nick'] ??
        appState.identityValues['firstName'] ??
        '';
    final ok = await ref
        .read(referralServiceProvider)
        .bindUplineReferrer(
          currentUid: uid,
          currentEmail: email,
          currentDisplayName: name.isNotEmpty ? name : null,
          referralCode: resolvedReferrer.code,
        );
    if (!mounted || !context.mounted) return;
    if (ok) {
      ref.invalidate(uplineReferrerProvider(uid));
      AppToast.showSuccess(context, strings.refUplineBoundSuccess);
    } else {
      AppToast.showError(context, strings.refUplineInvalidCode);
    }
  }

  Widget _buildUplineSection({
    required BuildContext context,
    required AppColors colors,
    required AppStrings strings,
    required String uid,
    required UplineReferrerInfo? upline,
  }) {
    if (upline != null) {
      return AppCard(
        key: const Key('ref_upline_locked_card'),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Row(
          children: [
            FaIcon(FontAwesomeIcons.userShield, size: 15, color: colors.ok),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.refUplineTitle,
                    style: AppTypography.caption(color: colors.mu),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    upline.code.isNotEmpty && upline.displayName != upline.code
                        ? '${upline.displayName} (${upline.code})'
                        : upline.displayName,
                    style: AppTypography.cardTitle(color: colors.tx),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppBadge(
              variant: AppBadgeVariant.success,
              size: AppBadgeSize.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 11, color: colors.ok),
                  const SizedBox(width: 4),
                  Text(strings.refUplineLockedBadge),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      key: const Key('ref_upline_empty_card'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.userPlus, size: 14, color: colors.pr),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.refUplineTitle,
                  style: AppTypography.cardTitle(color: colors.tx),
                ),
                Text(
                  strings.refUplineEmptyNotice,
                  style: AppTypography.caption(color: colors.mu),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton(
            key: const Key('ref_enter_code_btn'),
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            text: strings.refEnterCodeBtn,
            onPressed: uid.isNotEmpty
                ? () => _openEnterReferralDialog(context, strings, uid)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final uid = widget.uidOverride?.isNotEmpty == true
        ? widget.uidOverride!
        : _resolveEffectiveUid();
    final upline = uid.isNotEmpty
        ? ref.watch(uplineReferrerProvider(uid)).valueOrNull
        : null;

    final refCode = appState.referralCode.isNotEmpty
        ? appState.referralCode
        : (uid.length >= 8 ? uid.substring(0, 8).toUpperCase() : uid);
    final referralLink = refCode.isNotEmpty
        ? 'https://stylemorph-preview.web.app/?ref=$refCode'
        : 'https://stylemorph-preview.web.app/?ref=...';

    if (uid.isNotEmpty) {
      ref.listen<AsyncValue<List<ReferralEntry>>>(
        referralsStreamProvider(uid),
        (prev, next) {
          final list = next.valueOrNull;
          if (list != null) {
            ref
                .read(appStateProvider.notifier)
                .setReferralData(referrals: list);
          }
        },
      );
    }

    final liveReferralsAsync = uid.isNotEmpty
        ? ref.watch(referralsStreamProvider(uid))
        : null;

    final referrals = liveReferralsAsync?.valueOrNull ?? appState.referrals;
    final invitedCount = referrals.isNotEmpty
        ? referrals.length
        : appState.referralCount;
    final networkTier = referrals.isNotEmpty
        ? ReferralService.calculateTier(referrals.length)
        : appState.networkTier;
    final earnedCoins = referrals.isNotEmpty
        ? referrals.fold<int>(0, (sum, r) => sum + r.rewardEarned)
        : (invitedCount * 100);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top (Fixed) ──────────────────────────────────────────────
          AppSectionHeader(
            faIcon: FontAwesomeIcons.gift,
            title: strings.refHeader,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Upline Referrer Card (Locked if set, or Enter Referral Code button)
          _buildUplineSection(
            context: context,
            colors: colors,
            strings: strings,
            uid: uid,
            upline: upline,
          ),
          const SizedBox(height: AppSpacing.md),

          // 3-Column Stats Grid
          Row(
            children: [
              // Invited Count
              Expanded(
                child: _buildStatCard(
                  label: strings.refInvited,
                  value: strings.countWithUnit(
                    invitedCount,
                    strings.refMembersUnit,
                  ),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Bonus Earned
              Expanded(
                child: _buildStatCard(
                  label: strings.refBonus,
                  value: '${strings.formatNumber(earnedCoins)} ${strings.coin}',
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6),
              // Network Tier
              Expanded(
                child: _buildStatCard(
                  label: strings.refTier,
                  value: strings.getTierLabel(networkTier),
                  valueColor: colors.wn,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Compact Tap-to-Copy 8-Character Referral Code Box (no separate copy button)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: refCode.isNotEmpty
                  ? () {
                      Clipboard.setData(ClipboardData(text: refCode));
                      AppToast.showSuccess(context, strings.refCopiedToast);
                    }
                  : null,
              borderRadius: AppRadius.rLg,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: colors.sf,
                  borderRadius: AppRadius.rLg,
                  border: Border.all(color: colors.bd),
                ),
                child: Text(
                  refCode.isNotEmpty ? refCode : '...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Roboto', 'Arial', 'sans-serif'],
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: colors.pr,
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Referral Link Box (Full-Width, Single-Tap Native Share / Copy)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.refLinkLabel,
                style: AppTypography.inputLabel(color: colors.tx),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  strings.refTapToShare,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    color: colors.mu,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Material(
            key: const Key('ref_invite_link_tile'),
            color: Colors.transparent,
            child: InkWell(
              onTap: referralLink.isNotEmpty
                  ? () => _shareOrCopyLink(context, referralLink, strings)
                  : null,
              borderRadius: AppRadius.rLg,
              child: Container(
                height: 44,
                alignment: AlignmentDirectional.centerStart,
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.md,
                  end: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.rLg,
                  border: Border.all(color: colors.bd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        referralLink,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colors.tx,
                        ),
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FaIcon(
                      FontAwesomeIcons.shareNodes,
                      size: 13,
                      color: colors.pr,
                    ),
                    IconButton(
                      key: const Key('ref_copy_link_btn'),
                      tooltip: strings.refCopyLinkTooltip,
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: colors.mu,
                      ),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: referralLink.isNotEmpty
                          ? () {
                              Clipboard.setData(
                                ClipboardData(text: referralLink),
                              );
                              AppToast.showSuccess(
                                context,
                                strings.refCopiedToast,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Joined Friends Header
          Text(
            strings.refJoinedTitle,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Middle (Expanded — Fills ALL Remaining Vertical Space) ─────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.sf,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: colors.bd),
              ),
              clipBehavior: Clip.antiAlias,
              child: referrals.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.userGroup,
                              size: 24,
                              color: colors.mu,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              strings.refEmptyFriends,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: colors.mu,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        itemCount: referrals.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: colors.bd.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, index) {
                          final item = referrals[index];
                          return _buildFriendItem(item, colors, strings);
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Bottom (Pinned to Bottom Edge) ─────────────────────────────
          AppCard(
            backgroundColor: colors.wnb.withValues(alpha: 0.5),
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.circleQuestion,
                  size: 14,
                  color: colors.wn,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.refRuleInfo,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
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

  Widget _buildFriendItem(
    ReferralEntry item,
    AppColors colors,
    AppStrings strings,
  ) {
    final name = item.displayName.isNotEmpty
        ? item.displayName
        : (item.email.isNotEmpty ? item.email.split('@').first : 'User');
    final coinsStr = strings.formatNumber(item.rewardEarned);
    final badgeText = '+ $coinsStr ${strings.coin}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Name on start side, Earned Coins Badge on end side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.tx,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                variant: AppBadgeVariant.success,
                size: AppBadgeSize.sm,
                child: Text(badgeText),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Row 2: Invitee email address in clean, compact, smaller muted font directly underneath
          Text(
            item.email,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: colors.mu,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    Color? valueColor,
    required AppColors colors,
  }) {
    return AppCard(
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 9,
              color: colors.mu,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.tx,
            ),
          ),
        ],
      ),
    );
  }
}
