import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/services/two_factor_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
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
import 'two_factor_setup_dialog.dart';

// ── Remote sign-out & device block listener widget ────────────────────────

/// Wraps the app shell and listens in real-time to:
/// 1. This device's session doc (`users/{uid}/sessions/{sessionId}`)
/// 2. This device's blocked doc (`users/{uid}/blocked_devices/{deviceId}`)
/// If the session is deleted, inactive, or blocked by the Primary Device,
/// it signs out immediately and returns to [WelcomeScreen].
class SessionRevocationListener extends ConsumerStatefulWidget {
  final Widget child;

  @visibleForTesting
  static String? testUidOverride;

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
  bool _hasObservedExistingSession = false;
  String? _trackedUid;
  String? _trackedSessionId;

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
    if (Firebase.apps.isEmpty &&
        SessionRevocationListener.testUidOverride == null) {
      return;
    }
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    if (user == null && SessionRevocationListener.testUidOverride == null) {
      return;
    }
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

    if (Firebase.apps.isEmpty &&
        SessionRevocationListener.testUidOverride == null) {
      return;
    }
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;
    final uid = SessionRevocationListener.testUidOverride ?? user?.uid;
    if (uid == null) return;

    final service = ref.read(sessionServiceProvider);

    Future.wait([service.currentSessionId(), service.currentDeviceId()]).then((
      ids,
    ) {
      if (!mounted) return;
      final sessionId = ids[0];
      final deviceId = ids[1];

      if (_trackedUid != uid || _trackedSessionId != sessionId) {
        _trackedUid = uid;
        _trackedSessionId = sessionId;
        _hasObservedExistingSession = false;
      }

      // 1. Watch session document
      _sessionSub = service.watchCurrentSession(uid, sessionId).listen((snap) {
        if (!mounted) return;

        if (snap != null && snap.exists) {
          _hasObservedExistingSession = true;
          final isBlocked =
              (snap.data()?['isBlocked'] as bool? ?? false) == true;
          final inactive = (snap.data()?['isActive'] as bool? ?? true) == false;

          if (isBlocked) {
            _performBlockedSignOut();
          } else if (inactive) {
            _performSignOut('session_inactive');
          }
        } else {
          // snap == null || !snap.exists
          if (_hasObservedExistingSession) {
            _performSignOut('session_revoked');
          } else {
            debugPrint(
              '[SessionRevocationListener] Session document does not exist yet (waiting for upsertSession). Skipping sign out.',
            );
          }
        }
      });

      // 2. Watch blocked device document
      _blockedSub = service.watchDeviceBlocked(uid, deviceId).listen((
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
    debugPrint(
      '[SessionRevocationListener] Signing out: reason=device_blocked',
    );
    final notice = context.strings.sessDeviceBlockedNotice;

    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    if (mounted) {
      ref.read(appStateProvider.notifier).logout();
      AppToast.showError(context, notice, duration: const Duration(seconds: 4));
    }
  }

  Future<void> _performExpiredSignOut() async {
    debugPrint(
      '[SessionRevocationListener] Signing out: reason=session_expired',
    );
    final notice = context.strings.authSessionExpired;

    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    if (mounted) {
      ref.read(appStateProvider.notifier).logout();
      AppToast.showWarning(
        context,
        notice,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _performSignOut([String reason = 'session_revoked']) async {
    debugPrint('[SessionRevocationListener] Signing out: reason=$reason');
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {}
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    if (mounted) {
      ref.read(appStateProvider.notifier).logout();
    }
    try {
      await TwoFactorService.clearPersistedVerification();
    } catch (_) {}
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

  String _activeUid() {
    return SessionRevocationListener.testUidOverride ??
        currentAuthenticatedUid() ??
        '';
  }

  String _activeEmail() {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuth.instance.currentUser?.email ?? '';
    }
    return '';
  }

  Future<bool> _ensureTrustPeriodSatisfied(
    List<SessionInfo> sessions,
    String currentId,
  ) async {
    final currentSession = sessions.cast<SessionInfo?>().firstWhere(
      (s) => s?.sessionId == currentId,
      orElse: () => null,
    );
    if (currentSession == null) return true;

    final remaining = SessionService.remainingTrustDuration(currentSession);
    if (remaining <= Duration.zero) return true;

    final hours = remaining.inHours;
    final mins = remaining.inMinutes.remainder(60);
    final strings = context.strings;
    final colors = context.colors;
    final formatted =
        '${strings.formatNumber(hours.toString())}h ${strings.formatNumber(mins.toString())}m';

    await AppModal.showAppDialog<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, size: 20, color: colors.wn),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings.sessCooldownTitle,
                  style: AppTypography.sectionTitle(color: colors.tx),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            strings.sessCooldownMsg(formatted),
            style: AppTypography.bodyMedium(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              size: AppButtonSize.sm,
              text: strings.dialogConfirm,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
    return false;
  }

  Future<bool> _showStepUpOtpModal(TwoFactorConfig twoFactorConfig) async {
    final uid = _activeUid();
    final email = _activeEmail();
    final twoFactorService = ref.read(twoFactorServiceProvider);

    final verified = await AppModal.showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      child: _StepUpOtpDialog(
        uid: uid,
        email: email,
        config: twoFactorConfig,
        service: twoFactorService,
      ),
    );
    return verified ?? false;
  }

  Future<void> _handleBlock(
    SessionInfo session,
    List<SessionInfo> sessions,
    String currentId,
    TwoFactorConfig twoFactorConfig,
  ) async {
    if (!await _ensureTrustPeriodSatisfied(sessions, currentId)) return;
    if (!mounted) return;
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmBlockTitle,
      message: strings.sessConfirmBlockMsg,
      confirmText: strings.sessBlockBtn,
      confirmColor: colors.orColor,
      icon: LucideIcons.ban,
    );
    if (!confirmed || !mounted) return;
    if (!await _showStepUpOtpModal(twoFactorConfig)) return;

    final service = ref.read(sessionServiceProvider);
    await service.blockDevice(
      targetSessionId: session.sessionId,
      targetDeviceId: session.deviceId,
      deviceName: session.deviceName,
      deviceType: session.deviceType,
    );
  }

  Future<void> _handleUnblock(
    SessionInfo session,
    List<SessionInfo> sessions,
    String currentId,
    TwoFactorConfig twoFactorConfig,
  ) async {
    if (!await _ensureTrustPeriodSatisfied(sessions, currentId)) return;
    if (!mounted) return;
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmUnblockTitle,
      message: strings.sessConfirmUnblockMsg,
      confirmText: strings.sessUnblockBtn,
      confirmColor: colors.ok,
      icon: LucideIcons.shieldCheck,
    );
    if (!confirmed || !mounted) return;
    if (!await _showStepUpOtpModal(twoFactorConfig)) return;

    final service = ref.read(sessionServiceProvider);
    await service.unblockDevice(
      targetSessionId: session.sessionId,
      targetDeviceId: session.deviceId,
    );
  }

  Future<void> _handleDelete(
    SessionInfo session,
    List<SessionInfo> sessions,
    String currentId,
    TwoFactorConfig twoFactorConfig,
  ) async {
    if (!await _ensureTrustPeriodSatisfied(sessions, currentId)) return;
    if (!mounted) return;
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmDeleteTitle,
      message: strings.sessConfirmDeleteMsg,
      confirmText: strings.sessDelete,
      confirmColor: colors.orColor,
      icon: LucideIcons.trash2,
    );
    if (!confirmed || !mounted) return;
    if (!await _showStepUpOtpModal(twoFactorConfig)) return;

    final service = ref.read(sessionServiceProvider);
    await service.revokeSession(session.sessionId);
    final uid = currentAuthenticatedUid();
    if (uid != null) {
      unawaited(
        ref
            .read(notificationServiceProvider)
            .createNotification(
              uid: uid,
              title: strings.notifSessionRevokedTitle,
              body: session.deviceName,
              category: 'profile',
              targetRoute: 'profile_sessions',
              emoji: '🔐',
              sendEmail: false,
              eventType: 'session_revoked',
            )
            .catchError((_) {}),
      );
    }
  }

  Future<void> _handleRevokeAllOthers(
    List<SessionInfo> sessions,
    String currentId,
    TwoFactorConfig twoFactorConfig,
  ) async {
    if (!await _ensureTrustPeriodSatisfied(sessions, currentId)) return;
    if (!mounted) return;
    final strings = context.strings;
    final colors = context.colors;
    final confirmed = await _showConfirmModal(
      title: strings.sessConfirmTerminateAllTitle,
      message: strings.sessConfirmTerminateAllMsg,
      confirmText: strings.sessTerminateAll,
      confirmColor: colors.orColor,
      icon: LucideIcons.power,
    );
    if (!confirmed || !mounted) return;
    if (!await _showStepUpOtpModal(twoFactorConfig)) return;

    setState(() => _isTerminatingAll = true);
    try {
      final service = ref.read(sessionServiceProvider);
      await service.revokeAllOtherSessions();
      final uid = currentAuthenticatedUid();
      if (uid != null) {
        unawaited(
          ref
              .read(notificationServiceProvider)
              .createNotification(
                uid: uid,
                title: strings.notifSessionsRevokedAllTitle,
                body: strings.sessTerminateAll,
                category: 'profile',
                targetRoute: 'profile_sessions',
                emoji: '🛡️',
                sendEmail: false,
                eventType: 'sessions_revoked_all',
              )
              .catchError((_) {}),
        );
      }
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
    final uid = _activeUid();
    final twoFactorAsync = uid.isNotEmpty
        ? ref.watch(twoFactorConfigProvider(uid))
        : const AsyncValue<TwoFactorConfig>.data(TwoFactorConfig());
    final twoFactorConfig =
        twoFactorAsync.valueOrNull ?? const TwoFactorConfig();
    final loadedSessions = sessionsAsync.valueOrNull ?? const <SessionInfo>[];

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

          // ── Non-blocking 2FA security warning banner ──────────────────
          if (!twoFactorConfig.enabled) ...[
            AppCard(
              variant: AppCardVariant.surface,
              borderColor: colors.wn.withValues(alpha: 0.45),
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.shieldAlert, size: 18, color: colors.wn),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.sessTwoFaBannerTitle,
                              style: AppTypography.titleMedium(
                                color: colors.tx,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              strings.sessTwoFaBannerBody,
                              style: AppTypography.caption(color: colors.mu),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton(
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.sm,
                      text: strings.sessTwoFaBannerBtn,
                      onPressed: () => TwoFactorSetupDialog.show(
                        context,
                        currentConfig: twoFactorConfig,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

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
                  onPressed: _isTerminatingAll
                      ? null
                      : () => _handleRevokeAllOthers(
                          loadedSessions,
                          currentId,
                          twoFactorConfig,
                        ),
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

              return Column(
                children: [
                  for (final session in sessions) ...[
                    _SessionCard(
                      session: session,
                      isCurrentDevice: session.sessionId == currentId,
                      isExpanded: _expandedSessionId == session.sessionId,
                      colors: colors,
                      strings: strings,
                      onToggleExpand: () => _toggleExpand(session.sessionId),
                      onBlock: () => _handleBlock(
                        session,
                        sessions,
                        currentId,
                        twoFactorConfig,
                      ),
                      onUnblock: () => _handleUnblock(
                        session,
                        sessions,
                        currentId,
                        twoFactorConfig,
                      ),
                      onDelete: () => _handleDelete(
                        session,
                        sessions,
                        currentId,
                        twoFactorConfig,
                      ),
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
    AppToast.showSuccess(
      context,
      strings.sessCopiedToast,
      duration: const Duration(seconds: 2),
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
                  // Never show destructive buttons on This Device itself.
                  if (!isCurrentDevice) ...[
                    const SizedBox(height: 10),
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

// ── Step-Up 6-Digit OTP Verification Modal ──────────────────────────────────

class _StepUpOtpDialog extends StatefulWidget {
  final String uid;
  final String email;
  final TwoFactorConfig config;
  final TwoFactorService service;

  const _StepUpOtpDialog({
    required this.uid,
    required this.email,
    required this.config,
    required this.service,
  });

  @override
  State<_StepUpOtpDialog> createState() => _StepUpOtpDialogState();
}

class _StepUpOtpDialogState extends State<_StepUpOtpDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  String? _errorText;
  String? _previewHint;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  bool get _isTotp =>
      widget.config.enabled && widget.config.method == TwoFactorMethod.totp;

  @override
  void initState() {
    super.initState();
    if (!_isTotp) {
      _sendEmailOtp();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    final res = await widget.service.requestEmailOtp(
      uid: widget.uid,
      email: widget.email,
    );
    if (!mounted) return;
    setState(() {
      _previewHint = res.previewCode;
      _resendCooldown = res.cooldownRemainingSeconds > 0
          ? res.cooldownRemainingSeconds
          : (res.sent ? 60 : 0);
    });
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    if (_resendCooldown <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final otp = TwoFactorService.extractSixDigitOtp(data?.text ?? '');
    if (otp != null && mounted) {
      setState(() {
        _codeCtrl.text = otp;
        _errorText = null;
      });
    }
  }

  void _verify() {
    final normalized =
        TwoFactorService.extractSixDigitOtp(_codeCtrl.text) ??
        _codeCtrl.text.trim();
    final ok = widget.service.verifyStepUpCode(
      config: widget.config,
      uid: widget.uid,
      code: normalized,
    );
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorText = context.strings.sessStepUpInvalidCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(LucideIcons.shieldCheck, size: 20, color: colors.pr),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                strings.sessStepUpTitle,
                style: AppTypography.sectionTitle(color: colors.tx),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isTotp ? strings.sessStepUpTotpDesc : strings.sessStepUpEmailDesc,
          style: AppTypography.bodyMedium(color: colors.mu),
        ),
        if (_previewHint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Preview OTP: $_previewHint',
            style: AppTypography.caption(color: colors.wn),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _codeCtrl,
                placeholder: strings.sessStepUpCodeHint,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppButton(
              variant: AppButtonVariant.outline,
              size: AppButtonSize.sm,
              text: strings.sessStepUpPaste,
              onPressed: _pasteCode,
            ),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _errorText!,
            style: AppTypography.caption(color: colors.orColor),
          ),
        ],
        if (!_isTotp) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
              text: _resendCooldown > 0
                  ? '${strings.sessStepUpResend} (${strings.formatNumber(_resendCooldown.toString())}s)'
                  : strings.sessStepUpResend,
              onPressed: _resendCooldown > 0 ? null : _sendEmailOtp,
            ),
          ),
        ],
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
              variant: AppButtonVariant.primary,
              size: AppButtonSize.sm,
              text: strings.sessStepUpVerifyBtn,
              onPressed: _verify,
            ),
          ],
        ),
      ],
    );
  }
}
