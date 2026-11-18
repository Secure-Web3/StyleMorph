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

// ── Remote sign-out listener widget ────────────────────────────────────────

/// Wraps the app shell and listens to this device's Firestore session doc.
/// If the session is deleted or marked inactive from another device, it
/// immediately signs out and returns to [WelcomeScreen].
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

  @override
  void initState() {
    super.initState();
    _attachListener();
  }

  void _attachListener() {
    if (_listenerActive) return;
    _listenerActive = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final service = ref.read(sessionServiceProvider);

    service.currentSessionId().then((sessionId) {
      if (!mounted) return;

      service.watchCurrentSession(user.uid, sessionId).listen((snap) {
        if (!mounted) return;

        final deleted = snap == null || !snap.exists;
        final inactive = !deleted &&
            (snap.data()?['isActive'] as bool? ?? true) == false;

        if (deleted || inactive) {
          _performSignOut();
        }
      });
    });
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

  Future<void> _revokeSession(String targetSessionId) async {
    final service = ref.read(sessionServiceProvider);
    await service.revokeSession(targetSessionId);
  }

  Future<void> _signOutThisDevice() async {
    final colors = context.colors;
    final strings = context.strings;
    final confirmed = await AppModal.showAppDialog<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.rightFromBracket,
                size: 16,
                color: colors.orColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings.sessDelete,
                style: AppTypography.sectionTitle(color: colors.tx),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'آیا می‌خواهید از حساب کاربری در این دستگاه خارج شوید؟',
            style: AppTypography.bodyMedium(color: colors.mu),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                text: 'انصراف',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                variant: AppButtonVariant.destructive,
                size: AppButtonSize.sm,
                text: strings.sessDelete,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentId = await ref.read(currentSessionIdProvider.future);
      await ref.read(sessionServiceProvider).revokeSession(currentId);
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
  }

  Future<void> _revokeAllOthers() async {
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
                  onPressed: _isTerminatingAll ? null : _revokeAllOthers,
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
                '⚠ خطا در بارگذاری نشست‌ها',
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
                data: (currentId) => Column(
                  children: [
                    for (final session in sessions) ...[
                      _SessionCard(
                        session: session,
                        isCurrentDevice: session.sessionId == currentId,
                        colors: colors,
                        strings: strings,
                        onRevoke: () {
                          if (session.sessionId == currentId) {
                            _signOutThisDevice();
                          } else {
                            _revokeSession(session.sessionId);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
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
  final AppColors colors;
  final AppStrings strings;
  final VoidCallback onRevoke;

  const _SessionCard({
    required this.session,
    required this.isCurrentDevice,
    required this.colors,
    required this.strings,
    required this.onRevoke,
  });

  IconData _platformIcon() {
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 2) return 'همین الان';
    if (diff.inHours < 1) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  void _copySessionId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: session.sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'شناسه نشست کپی شد',
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

    return AppCard(
      variant: AppCardVariant.surface,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      borderColor: isCurrentDevice ? colors.ok : colors.bd,
      borderWidth: isCurrentDevice ? 1.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Icon + Device name + Current badge + Delete button ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrentDevice ? colors.okb : colors.inb,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _platformIcon(),
                  size: 20,
                  color: isCurrentDevice ? colors.ok : colors.inColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            session.deviceName,
                            style: AppTypography.titleMedium(color: colors.tx),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentDevice) ...[
                          const SizedBox(width: AppSpacing.xs),
                          AppBadge(
                            variant: AppBadgeVariant.success,
                            size: AppBadgeSize.sm,
                            child: Text(strings.sessCurrentDevice),
                          ),
                        ],
                      ],
                    ),
                    if (session.deviceModel.isNotEmpty)
                      Text(
                        session.deviceModel,
                        style: AppTypography.caption(color: colors.mu),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Delete/revoke button
              InkWell(
                onTap: onRevoke,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: FaIcon(
                    FontAwesomeIcons.trash,
                    size: 14,
                    color: isCurrentDevice ? colors.mu : colors.orColor,
                  ),
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
            value: _formatDate(session.createdAt),
            colors: colors,
          ),
          _InfoRow(
            icon: FontAwesomeIcons.clock,
            label: strings.sessLastActive,
            value: _formatDate(session.lastActiveAt),
            colors: colors,
          ),

          // ── Session ID chip ────────────────────────────────────────────
          const SizedBox(height: AppSpacing.xs),
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
