import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
    extends ConsumerState<SessionRevocationListener>
    with WidgetsBindingObserver {
  bool _listenerActive = false;
  StreamSubscription? _sessionSub;
  StreamSubscription? _blockedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionSub?.cancel();
    _blockedSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionExpiry();
    }
  }

  Future<void> _checkSessionExpiry() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final isExpired = await ref
        .read(sessionServiceProvider)
        .checkSessionExpiryAndSignOutIfExpired();
    if (isExpired && mounted) {
      _performExpiredSignOut();
    }
  }

  void _attachListener() {
    if (_listenerActive) return;
    _listenerActive = true;

    // Check 5-day session expiry upon initial attachment
    _checkSessionExpiry();

    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final service = ref.read(sessionServiceProvider);

    Future.wait([service.currentSessionId(), service.currentDeviceId()]).then((
      ids,
    ) {
      if (!mounted) return;
      final sessionId = ids[0];
      final deviceId = ids[1];

      // 1. Watch session document
      _sessionSub = service.watchCurrentSession(user.uid, sessionId).listen((
        snap,
      ) {
        if (!mounted) return;

        final deleted = snap == null || !snap.exists;
        final isBlocked =
            !deleted && (snap.data()?['isBlocked'] as bool? ?? false) == true;
        final inactive =
            !deleted && (snap.data()?['isActive'] as bool? ?? true) == false;

        if (isBlocked) {
          _performBlockedSignOut();
        } else if (deleted || inactive) {
          _performSignOut();
        }
      });

      // 2. Watch blocked device document
      _blockedSub = service.watchDeviceBlocked(user.uid, deviceId).listen((
        isBlocked,
      ) {
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

  Future<void> _performExpiredSignOut() async {
    final messenger = ScaffoldMessenger.of(context);
    final notice = context.strings.authSessionExpired;
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
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(sessionServiceProvider).recordUserActivityThrottled();
      },
      child: widget.child,
    );
  }
}

// ── Sessions sub-tab ────────────────────────────────────────────────────────

class SessionsSubTab extends ConsumerStatefulWidget {
  const SessionsSubTab({super.key});

  @override
  ConsumerState<SessionsSubTab> createState() => _SessionsSubTabState();
}

class _SessionsSubTabState extends ConsumerState<SessionsSubTab> {
  bool _isTerminatingAll = false;
  String? _expandedSessionId;

  // Auto-retry state for session stream & document synchronization
  int _retryAttempt = 0;
  static const int _maxRetryAttempts = 4;
  Timer? _retryTimer;
  bool _isAutoRetrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionServiceProvider).upsertSession().catchError((e) {
        debugPrint('[SessionsSubTab] upsertSession on mount error: $e');
      });
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoRetry() {
    if (_retryAttempt >= _maxRetryAttempts || _isAutoRetrying || !mounted) {
      return;
    }
    _retryTimer?.cancel();

    // Gentle backoff: 1.5s -> 3s -> 5s -> 5s
    final delays = [
      const Duration(milliseconds: 1500),
      const Duration(milliseconds: 3000),
      const Duration(milliseconds: 5000),
      const Duration(milliseconds: 5000),
    ];
    final delay = delays[_retryAttempt.clamp(0, delays.length - 1)];

    _retryTimer = Timer(delay, () async {
      if (!mounted) return;
      _isAutoRetrying = true;
      _retryAttempt++;
      debugPrint(
        '[SessionsSubTab] Auto-retry attempt $_retryAttempt/$_maxRetryAttempts...',
      );
      try {
        await ref.read(sessionServiceProvider).upsertSession();
        if (mounted) {
          ref.invalidate(allSessionsProvider);
        }
      } catch (e) {
        debugPrint('[SessionsSubTab] Auto-retry upsertSession error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isAutoRetrying = false;
          });
        }
      }
    });
  }

  void _toggleExpand(String sessionId) {
    setState(() {
      _expandedSessionId = (_expandedSessionId == sessionId) ? null : sessionId;
    });
  }

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
          Text(message, style: AppTypography.bodyMedium(color: colors.mu)),
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
      icon: LucideIcons.ban,
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
      icon: LucideIcons.shieldCheck,
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
      icon: LucideIcons.trash2,
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
      icon: LucideIcons.power,
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
    final currentId = currentSessionAsync.valueOrNull ?? '';

    // Evaluate auto-retry state whenever sessionsAsync updates
    sessionsAsync.when(
      data: (sessions) {
        final currentFound = currentId.isNotEmpty
            ? sessions.any((s) => s.sessionId == currentId)
            : sessions.isNotEmpty;

        if (sessions.isEmpty || !currentFound) {
          if (_retryAttempt < _maxRetryAttempts && !_isAutoRetrying) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scheduleAutoRetry();
            });
          }
        } else {
          if (_retryAttempt > 0 || _retryTimer != null) {
            _retryTimer?.cancel();
            _retryTimer = null;
            _retryAttempt = 0;
          }
        }
      },
      error: (_, _) {
        if (_retryAttempt < _maxRetryAttempts && !_isAutoRetrying) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scheduleAutoRetry();
          });
        }
      },
      loading: () {},
    );

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          AppSectionHeader(
            icon: LucideIcons.monitorSmartphone,
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
            error: (err, stack) {
              debugPrint(
                '[SessionsSubTab] Firestore exception loading sessions: $err',
              );
              if (_retryAttempt < _maxRetryAttempts) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.pr,
                    ),
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.shieldAlert, size: 36, color: colors.mu),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        strings.sessEmpty,
                        style: AppTypography.bodyMedium(color: colors.mu),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (sessions) {
              if (sessions.isEmpty) {
                if (_retryAttempt < _maxRetryAttempts) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.pr,
                      ),
                    ),
                  );
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.monitorOff,
                          size: 36,
                          color: colors.mu,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          strings.sessEmpty,
                          style: AppTypography.bodyMedium(color: colors.mu),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Legacy fallback: if NO session document has isPrimary == true,
              // treat the earliest session (oldest createdAt) as Primary
              final hasExplicitPrimary = sessions.any((s) => s.isPrimary);
              String? fallbackPrimaryId;
              if (!hasExplicitPrimary && sessions.isNotEmpty) {
                final earliest = sessions.reduce(
                  (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
                );
                fallbackPrimaryId = earliest.sessionId;
              }

              final currentSession = sessions.cast<SessionInfo?>().firstWhere(
                (s) => s?.sessionId == currentId,
                orElse: () => null,
              );
              final isCurrentDevicePrimary =
                  (currentSession?.isPrimary ?? false) ||
                  (fallbackPrimaryId != null && currentId == fallbackPrimaryId);

              return Column(
                children: [
                  for (final session in sessions) ...[
                    _SessionCard(
                      session: session,
                      isCurrentDevice: session.sessionId == currentId,
                      isPrimary:
                          session.isPrimary ||
                          (session.sessionId == fallbackPrimaryId),
                      isViewerPrimary: isCurrentDevicePrimary,
                      isExpanded: _expandedSessionId == session.sessionId,
                      colors: colors,
                      strings: strings,
                      onToggleExpand: () => _toggleExpand(session.sessionId),
                      onBlock: () => _handleBlock(session),
                      onUnblock: () => _handleUnblock(session),
                      onDelete: () => _handleDelete(session),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Expandable Accordion Session Card ────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final SessionInfo session;
  final bool isCurrentDevice;
  final bool isPrimary;
  final bool isViewerPrimary;
  final bool isExpanded;
  final AppColors colors;
  final AppStrings strings;
  final VoidCallback onToggleExpand;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.isCurrentDevice,
    required this.isPrimary,
    required this.isViewerPrimary,
    required this.isExpanded,
    required this.colors,
    required this.strings,
    required this.onToggleExpand,
    required this.onBlock,
    required this.onUnblock,
    required this.onDelete,
  });

  IconData _platformIcon() {
    final dType = session.deviceType.toLowerCase();
    final plat = session.platform.toLowerCase();
    final dName = session.deviceName.toLowerCase();

    // 1. Desktop Web
    if (dType == 'desktop_web' ||
        (plat == 'web' &&
            !dName.contains('mobile') &&
            !dName.contains('iphone') &&
            !dName.contains('android'))) {
      return Icons.computer_rounded;
    }

    // 2. Mobile Web
    if (dType == 'mobile_web' ||
        (plat == 'web' &&
            (dName.contains('mobile') ||
                dName.contains('iphone') ||
                dName.contains('android')))) {
      return Icons.phonelink_rounded;
    }

    // 3. Android App
    if (plat == 'android' ||
        (dType == 'mobile_app' && dName.contains('android')) ||
        dName.contains('android')) {
      return Icons.android_rounded;
    }

    // 4. iPhone / iOS App
    if (plat == 'ios' ||
        dName.contains('iphone') ||
        dName.contains('ipad') ||
        dName.contains('ios')) {
      return Icons.phone_iphone_rounded;
    }

    // Fallbacks
    if (plat == 'web') return Icons.computer_rounded;
    if (plat == 'android') return Icons.android_rounded;
    if (plat == 'ios') return Icons.phone_iphone_rounded;
    return Icons.computer_rounded;
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

  Widget _buildActionButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: 0.10),
        splashColor: color.withValues(alpha: 0.18),
        highlightColor: color.withValues(alpha: 0.12),
        child: Container(
          height: 38,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isCurrentDevice
        ? colors.ok
        : (session.isBlocked ? colors.orColor : colors.bd);

    final double borderWidth = isCurrentDevice ? 1.5 : 1.0;

    // High contrast explicit colors for the platform icon box
    final Color accentColor = isCurrentDevice
        ? colors.ok
        : (session.isBlocked ? colors.orColor : colors.pr);

    final Color iconBoxBg = accentColor.withValues(alpha: 0.14);
    final Color iconBoxFg = accentColor;

    return AppCard(
      variant: AppCardVariant.surface,
      padding: EdgeInsetsDirectional.zero,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Collapsed Header (Tap to toggle expand) ─────────────────────
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Row(
                children: [
                  // High-contrast Platform Icon Box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBoxBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(_platformIcon(), size: 22, color: iconBoxFg),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Device Title & Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.deviceName,
                          style: AppTypography.titleMedium(color: colors.tx),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 2,
                          children: [
                            if (isPrimary)
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
                  const SizedBox(width: AppSpacing.xs),

                  // Rotating Chevron Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Body Content (Animated Expansion) ───────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(height: 1, color: colors.bd),
                  const SizedBox(height: AppSpacing.sm),

                  // Metadata Rows
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
                    icon: FontAwesomeIcons.networkWired,
                    label: strings.sessIpAddress,
                    value:
                        (session.ipAddress != null &&
                            session.ipAddress!.trim().isNotEmpty)
                        ? session.ipAddress!
                        : strings.commonUnavailable,
                    colors: colors,
                  ),
                  _InfoRow(
                    icon: FontAwesomeIcons.locationDot,
                    label: strings.sessIpLocation,
                    value:
                        (session.ipLocation != null &&
                            session.ipLocation!.trim().isNotEmpty)
                        ? session.ipLocation!
                        : strings.commonUnavailable,
                    colors: colors,
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
                  const SizedBox(height: AppSpacing.sm),

                  // ── Expanded Footer: Two-tier responsive layout ───────────
                  // Row 1 (Full Width): Copyable Session ID chip with ellipsis protection
                  InkWell(
                    onTap: () => _copySessionId(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.bd),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.fingerprint,
                            size: 12,
                            color: colors.mu,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              session.sessionId,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: colors.mu,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          FaIcon(
                            FontAwesomeIcons.copy,
                            size: 11,
                            color: colors.mu,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Row 2 (Two Equal Side-by-Side Action Buttons separated by 10 spacing):
                  // STRICT CONSTRAINT: Never show destructive buttons on This Device or Primary Device!
                  if (!isCurrentDevice && !isPrimary) ...[
                    const SizedBox(height: 10),
                    if (isViewerPrimary) ...[
                      Row(
                        children: [
                          Expanded(
                            child: session.isBlocked
                                ? _buildActionButton(
                                    color: colors.ok,
                                    icon: LucideIcons.shieldCheck,
                                    label: strings.sessUnblockBtn,
                                    onTap: onUnblock,
                                  )
                                : _buildActionButton(
                                    color: colors.orColor,
                                    icon: LucideIcons.ban,
                                    label: strings.sessBlockBtn,
                                    onTap: onBlock,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              color: colors.orColor,
                              icon: LucideIcons.trash2,
                              label: strings.sessDelete,
                              onTap: onDelete,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              color: colors.orColor,
                              icon: LucideIcons.trash2,
                              label: strings.sessDelete,
                              onTap: onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
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
          Text('$label: ', style: AppTypography.caption(color: colors.mu)),
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
