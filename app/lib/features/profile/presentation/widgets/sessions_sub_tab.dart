import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../auth/presentation/auth_provider.dart';

// ── Remote sign-out & device block listener widget ────────────────────────

/// Wraps the app shell and listens in real-time to:
/// 1. This device's session doc (`users/{uid}/sessions/{sessionId}`)
/// 2. This device's blocked doc (`users/{uid}/blocked_devices/{deviceId}`)
/// If the session is deleted, inactive, or blocked by the Primary Device,
/// it signs out immediately and returns to [WelcomeScreen].
class SessionRevocationListener extends ConsumerStatefulWidget {
  final Widget child;

  const SessionRevocationListener({super.key, required this.child});

  @override
  ConsumerState<SessionRevocationListener> createState() =>
      _SessionRevocationListenerState();
}

class _SessionRevocationListenerState
    extends ConsumerState<SessionRevocationListener> {
  bool _listenerActive = false;
  StreamSubscription? _sessionSub;
  StreamSubscription? _blockedSub;

  @override
  void initState() {
    super.initState();
    _attachListener();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _blockedSub?.cancel();
    super.dispose();
  }

  void _attachListener() {
    if (_listenerActive) return;
    _listenerActive = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final service = ref.read(sessionServiceProvider);

    Future.wait([
      service.currentSessionId(),
      service.currentDeviceId(),
    ]).then((ids) {
      if (!mounted) return;
      final sessionId = ids[0];
      final deviceId = ids[1];

      // 1. Watch session document
      _sessionSub =
          service.watchCurrentSession(user.uid, sessionId).listen((snap) {
        if (!mounted) return;

        final deleted = snap == null || !snap.exists;
        final isBlocked = !deleted &&
            (snap.data()?['isBlocked'] as bool? ?? false) == true;
        final inactive = !deleted &&
            (snap.data()?['isActive'] as bool? ?? true) == false;

        if (isBlocked) {
          _performBlockedSignOut();
        } else if (deleted || inactive) {
          _performSignOut();
        }
      });

      // 2. Watch blocked device document
      _blockedSub =
          service.watchDeviceBlocked(user.uid, deviceId).listen((isBlocked) {
        if (!mounted) return;
        if (isBlocked) {
          _performBlockedSignOut();
        }
      });
    });
  }

  Future<void> _performBlockedSignOut() async {
    final messenger = ScaffoldMessenger.of(context);
    final notice = context.strings.sessDeviceBlockedNotice;
    final alertColor = context.colors.orColor;

    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) {
      ref.read(appStateProvider.notifier).logout();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            notice,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          backgroundColor: alertColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _performSignOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) {
      ref.read(appStateProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Sessions sub-tab ────────────────────────────────────────────────────────

class SessionsSubTab extends ConsumerStatefulWidget {
  const SessionsSubTab({super.key});

  @override
  ConsumerState<SessionsSubTab> createState() => _SessionsSubTabState();
}

class _SessionsSubTabState extends ConsumerState<SessionsSubTab> {
  bool _isTerminatingAll = false;

  Future<bool> _showConfirmModal({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) async {
    final colors = context.colors;
    final strings = context.strings;

    final result = await AppModal.showAppDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: confirmColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.sectionTitle(color: colors.tx),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.bodyMedium(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                text: strings.dialogCancel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.sm,
                text: confirmText,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBlock(SessionInfo session) async {
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmBlockTitle,
      message: strings.sessConfirmBlockMsg,
      confirmText: strings.sessBlockBtn,
      confirmColor: colors.orColor,
      icon: Icons.block_rounded,
    );
    if (!confirmed) return;

    final service = ref.read(sessionServiceProvider);
    await service.blockDevice(
      targetSessionId: session.sessionId,
      targetDeviceId: session.deviceId,
      deviceName: session.deviceName,
      deviceType: session.deviceType,
    );
  }

  Future<void> _handleUnblock(SessionInfo session) async {
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmUnblockTitle,
      message: strings.sessConfirmUnblockMsg,
      confirmText: strings.sessUnblockBtn,
      confirmColor: colors.ok,
      icon: Icons.lock_open_rounded,
    );
    if (!confirmed) return;

    final service = ref.read(sessionServiceProvider);
    await service.unblockDevice(
      targetSessionId: session.sessionId,
      targetDeviceId: session.deviceId,
    );
  }

  Future<void> _handleDelete(SessionInfo session) async {
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmDeleteTitle,
      message: strings.sessConfirmDeleteMsg,
      confirmText: strings.sessDelete,
      confirmColor: colors.orColor,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;

    final service = ref.read(sessionServiceProvider);
    await service.revokeSession(session.sessionId);
  }

  Future<void> _handleRevokeAllOthers() async {
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmTerminateAllTitle,
      message: strings.sessConfirmTerminateAllMsg,
      confirmText: strings.sessTerminateAll,
      confirmColor: colors.orColor,
      icon: Icons.power_settings_new_rounded,
    );
    if (!confirmed) return;

    setState(() => _isTerminatingAll = true);
    try {
      final service = ref.read(sessionServiceProvider);
      await service.revokeAllOtherSessions();
    } finally {
      if (mounted) setState(() => _isTerminatingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    final sessionsAsync = ref.watch(allSessionsProvider);
    final currentSessionAsync = ref.watch(currentSessionIdProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          AppSectionHeader(
            icon: Icons.devices_rounded,
            title: strings.sessHeader,
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Subtitle + Terminate All button ───────────────────────────
          AppCard(
            variant: AppCardVariant.subtle,
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.sessSubtitle,
                  style: AppTypography.bodyMedium(color: colors.mu),
                  textDirection: Directionality.of(context),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  variant: AppButtonVariant.destructive,
                  size: AppButtonSize.sm,
                  isFullWidth: true,
                  icon: _isTerminatingAll
                      ? null
                      : FaIcon(
                          FontAwesomeIcons.rightFromBracket,
                          size: 13,
                          color: colors.orColor,
                        ),
                  text: _isTerminatingAll ? null : strings.sessTerminateAll,
                  onPressed: _isTerminatingAll ? null : _handleRevokeAllOthers,
                  child: _isTerminatingAll
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.orColor,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Sessions list ─────────────────────────────────────────────
          sessionsAsync.when(
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.pr,
                ),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                strings.sessErrLoad,
                style: AppTypography.bodyMedium(color: colors.orColor),
              ),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      strings.sessEmpty,
                      style: AppTypography.bodyMedium(color: colors.mu),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return currentSessionAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (currentId) {
                  // Determine whether the current viewing device is Primary
                  final currentSession = sessions.cast<SessionInfo?>().firstWhere(
                        (s) => s?.sessionId == currentId,
                        orElse: () => null,
                      );
                  final isCurrentDevicePrimary =
                      currentSession?.isPrimary ?? false;

                  return Column(
                    children: [
                      for (final session in sessions) ...[
                        _SessionCard(
                          session: session,
                          isCurrentDevice: session.sessionId == currentId,
                          isViewerPrimary: isCurrentDevicePrimary,
                          colors: colors,
                          strings: strings,
                          onBlock: () => _handleBlock(session),
                          onUnblock: () => _handleUnblock(session),
                          onDelete: () => _handleDelete(session),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Individual session card ──────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final SessionInfo session;
  final bool isCurrentDevice;
  final bool isViewerPrimary;
  final AppColors colors;
  final AppStrings strings;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isCurrentDevice,
    required this.isViewerPrimary,
    required this.colors,
    required this.strings,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
  });

  IconData _platformIcon() {
    switch (session.deviceType) {
      case 'mobile_web':
        return Icons.smartphone_rounded;
      case 'desktop_web':
        return Icons.laptop_chromebook_rounded;
      case 'mobile_app':
        return Icons.phone_android_rounded;
      case 'desktop_app':
        return Icons.desktop_windows_rounded;
      default:
        switch (session.platform.toLowerCase()) {
          case 'android':
            return Icons.android_rounded;
          case 'ios':
            return Icons.phone_iphone_rounded;
          case 'web':
            return Icons.language_rounded;
          case 'desktop':
            return Icons.computer_rounded;
          default:
            return Icons.devices_rounded;
        }
    }
  }

  void _copySessionId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: session.sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          strings.sessCopiedToast,
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        backgroundColor: colors.ok,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortId = session.sessionId.length > 16
        ? '${session.sessionId.substring(0, 16)}…'
        : session.sessionId;

    final Color borderColor = isCurrentDevice
        ? colors.ok
        : (session.isBlocked ? colors.orColor : colors.bd);

    final double borderWidth = isCurrentDevice ? 1.5 : 1.0;

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Icon + Device name + Badges ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrentDevice
                      ? colors.okb
                      : (session.isBlocked ? colors.orb : colors.inb),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _platformIcon(),
                  size: 20,
                  color: isCurrentDevice
                      ? colors.ok
                      : (session.isBlocked ? colors.orColor : colors.inColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.deviceName,
                      style: AppTypography.titleMedium(color: colors.tx),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 2,
                      children: [
                        if (session.isPrimary)
                          AppBadge(
                            variant: AppBadgeVariant.active,
                            size: AppBadgeSize.sm,
                            child: Text(strings.sessPrimaryBadge),
                          ),
                        if (isCurrentDevice)
                          AppBadge(
                            variant: AppBadgeVariant.success,
                            size: AppBadgeSize.sm,
                            child: Text(strings.sessCurrentDevice),
                          ),
                        if (session.isBlocked)
                          AppBadge(
                            variant: AppBadgeVariant.destructive,
                            size: AppBadgeSize.sm,
                            child: Text(strings.sessBlockedBadge),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: colors.bd),
          const SizedBox(height: AppSpacing.sm),

          // ── Row 2: Metadata grid ───────────────────────────────────────
          _InfoRow(
            icon: FontAwesomeIcons.layerGroup,
            label: strings.sessPlatform,
            value: session.platform,
            colors: colors,
          ),
          if (session.osVersion.isNotEmpty)
            _InfoRow(
              icon: FontAwesomeIcons.microchip,
              label: strings.sessOs,
              value: session.osVersion,
              colors: colors,
            ),
          if (session.userAgent.isNotEmpty)
            _InfoRow(
              icon: FontAwesomeIcons.globe,
              label: strings.sessUserAgent,
              value: session.userAgent,
              colors: colors,
              maxLines: 2,
            ),
          _InfoRow(
            icon: FontAwesomeIcons.rightToBracket,
            label: strings.sessLoginTime,
            value: strings.formatRelativeTime(session.createdAt),
            colors: colors,
          ),
          _InfoRow(
            icon: FontAwesomeIcons.clock,
            label: strings.sessLastActive,
            value: strings.formatRelativeTime(session.lastActiveAt),
            colors: colors,
          ),

          // ── Row 3: Session ID chip + Action buttons ─────────────────────
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              GestureDetector(
                onTap: () => _copySessionId(context),
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.bd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.fingerprint,
                        size: 11,
                        color: colors.mu,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        shortId,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: colors.mu,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      FaIcon(
                        FontAwesomeIcons.copy,
                        size: 10,
                        color: colors.mu,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // ── Action Buttons ───────────────────────────────────────────
              // STRICT RULE: Current device has NO action buttons.
              // Primary device can NEVER be deleted or blocked.
              if (!isCurrentDevice && !session.isPrimary) ...[
                if (isViewerPrimary) ...[
                  if (session.isBlocked)
                    AppButton(
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 11),
                      text: strings.sessUnblockBtn,
                      onPressed: onUnblock,
                    )
                  else ...[
                    AppButton(
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      icon: FaIcon(
                        FontAwesomeIcons.ban,
                        size: 11,
                        color: colors.orColor,
                      ),
                      text: strings.sessBlockBtn,
                      onPressed: onBlock,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: FaIcon(
                          FontAwesomeIcons.trash,
                          size: 13,
                          color: colors.orColor,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Secondary device viewing another secondary session: can delete only
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: FaIcon(
                        FontAwesomeIcons.trash,
                        size: 13,
                        color: colors.orColor,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info row helper ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String value;
  final AppColors colors;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 11, color: colors.mu),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: AppTypography.caption(color: colors.mu),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption(color: colors.tx),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
