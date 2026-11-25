import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import 'widgets/about_sub_tab.dart';
import 'widgets/ai_dna_sub_tab.dart';
import 'widgets/gallery_sub_tab.dart';
import 'widgets/identity_sub_tab.dart';
import 'widgets/persona_sub_tab.dart';
import 'widgets/referral_sub_tab.dart';
import 'widgets/sessions_sub_tab.dart';
import 'widgets/settings_sub_tab.dart';
import 'widgets/unsaved_changes_dialog.dart';
import 'widgets/wallet_sub_tab.dart';
import '../domain/identity_validator.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  static const Set<String> _editableTabs = {
    'p-identity',
    'p-ai',
    'p-companion',
    'p-settings',
  };

  final Map<String, ScrollController> _subTabScrollControllers = {};

  ScrollController _scrollControllerFor(String tabId) {
    return _subTabScrollControllers.putIfAbsent(tabId, ScrollController.new);
  }

  @override
  void dispose() {
    for (final controller in _subTabScrollControllers.values) {
      controller.dispose();
    }
    _subTabScrollControllers.clear();
    super.dispose();
  }

  bool _isIdentityValid(Map<String, String> values) {
    final first = values['firstName']?.trim() ?? '';
    if (first.isNotEmpty && !IdentityValidator.isValidName(first)) return false;

    final last = values['lastName']?.trim() ?? '';
    if (last.isNotEmpty && !IdentityValidator.isValidName(last)) return false;

    final nick = values['nick']?.trim() ?? '';
    if (nick.isNotEmpty && !IdentityValidator.isValidHandle(nick)) return false;

    final dob = values['dob']?.trim() ?? '';
    if (dob.isNotEmpty) {
      final age = IdentityValidator.calculateAge(dob);
      if (age == null || age < 13) return false;
    }

    final nid = values['nid']?.trim() ?? '';
    if (nid.isNotEmpty) {
      final country = (values['countryCode'] ?? 'IR').toUpperCase();
      if (country == 'IR' && !IdentityValidator.isValidIranianNationalId(nid)) {
        return false;
      } else if (country == 'TR' &&
          !IdentityValidator.isValidTurkishKimlik(nid)) {
        return false;
      } else if (!IdentityValidator.isValidInternationalNationalId(nid)) {
        return false;
      }
    }

    final zip = values['zip']?.trim() ?? '';
    if (zip.isNotEmpty) {
      final country = (values['countryCode'] ?? 'IR').toUpperCase();
      if (country == 'IR' && !IdentityValidator.isValidIranianPostalCode(zip)) {
        return false;
      } else if (country == 'TR' &&
          !IdentityValidator.isValidTurkishPostalCode(zip)) {
        return false;
      } else if (!IdentityValidator.isValidInternationalPostalCode(zip)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _handleSubTabSwitch(String targetId) async {
    final appState = ref.read(appStateProvider);
    if (targetId == appState.currentProfileTab) return;

    if (appState.hasUnsavedChanges) {
      final action = await UnsavedChangesDialog.show(context);
      if (!mounted) return;

      if (action == UnsavedChangesAction.saveAndContinue) {
        if (!_isIdentityValid(appState.identityValues)) {
          final strings = context.strings;
          AppToast.showWarning(context, strings.idErrValidationSummary);
          return;
        }

        final success = await ref
            .read(appStateProvider.notifier)
            .saveProfileToFirestore();
        if (!mounted) return;
        if (success) {
          ref.read(appStateProvider.notifier).switchProfileTab(targetId);
        } else {
          final strings = context.strings;
          AppToast.showError(context, strings.profileSaveErrorToast);
        }
      } else if (action == UnsavedChangesAction.discardAndLeave) {
        ref.read(appStateProvider.notifier).discardUnsavedChanges();
        ref.read(appStateProvider.notifier).switchProfileTab(targetId);
      }
      return;
    }

    ref.read(appStateProvider.notifier).switchProfileTab(targetId);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(sessionServiceProvider).upsertSession().catchError((e) {
        debugPrint('[ProfileTab] upsertSession error: $e');
      });
      final appState = ref.read(appStateProvider);
      final currentUid = Firebase.apps.isNotEmpty
          ? FirebaseAuth.instance.currentUser?.uid
          : null;
      if (!appState.isProfileLoaded ||
          (currentUid != null && appState.loadedUid != currentUid)) {
        ref.read(appStateProvider.notifier).loadProfileFromFirestore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final activeTabId = ref.watch(
      appStateProvider.select((s) => s.currentProfileTab),
    );
    final isTermsUnsigned = ref.watch(
      appStateProvider.select((s) => s.termsAcceptedAt == null),
    );
    final isAdvanced = ref.watch(
      appStateProvider.select((s) => s.isAdvancedMode),
    );
    final isEditableTab = _editableTabs.contains(activeTabId);

    final sessionsAsync = ref.watch(allSessionsProvider);
    final activeSessionsCount = sessionsAsync.valueOrNull
        ?.where((s) => !s.isBlocked && s.isActive)
        .length;

    final subTabs = [
      _SubTabMeta('p-identity', strings.tIdent, FontAwesomeIcons.idCard),
      _SubTabMeta('p-gallery', strings.tGal, FontAwesomeIcons.images),
      _SubTabMeta('p-ai', strings.tAi, FontAwesomeIcons.dna),
      _SubTabMeta(
        'p-wallet',
        strings.tWal,
        FontAwesomeIcons.wallet,
        isEnabled: false,
        badgeText: strings.commonComingSoon,
      ),
      _SubTabMeta('p-referral', strings.tRef, FontAwesomeIcons.gift),
      _SubTabMeta(
        'p-companion',
        strings.tComp,
        FontAwesomeIcons.wandMagicSparkles,
        isEnabled: false,
        badgeText: strings.commonComingSoon,
      ),
      if (isAdvanced)
        _SubTabMeta('p-sessions', strings.tSess, Icons.devices_rounded),
      _SubTabMeta('p-settings', strings.tSet, FontAwesomeIcons.sliders),
      _SubTabMeta('p-about', strings.tAbout, Icons.info_outline_rounded),
    ];

    Widget activeContent;
    switch (activeTabId) {
      case 'p-identity':
        activeContent = const IdentitySubTab();
        break;
      case 'p-gallery':
        activeContent = const GallerySubTab();
        break;
      case 'p-ai':
        activeContent = const AiDnaSubTab();
        break;
      case 'p-wallet':
        activeContent = const WalletSubTab();
        break;
      case 'p-referral':
        activeContent = const ReferralSubTab();
        break;
      case 'p-companion':
        activeContent = const PersonaSubTab();
        break;
      case 'p-sessions':
        activeContent = isAdvanced
            ? const SessionsSubTab()
            : const IdentitySubTab();
        break;
      case 'p-settings':
        activeContent = const SettingsSubTab();
        break;
      case 'p-about':
        activeContent = const AboutSubTab();
        break;
      default:
        activeContent = const IdentitySubTab();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactSidebar = constraints.maxHeight < 560;
        final itemVerticalPad = compactSidebar ? 3.0 : 6.0;
        final firstBottomTabId = isAdvanced ? 'p-sessions' : 'p-settings';

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Start Sidebar Navigation (Fixed width 82px, NON-scrolling) ──
              Container(
                width: 82,
                decoration: BoxDecoration(
                  color: colors.sf,
                  border: BorderDirectional(end: BorderSide(color: colors.bd)),
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (int i = 0; i < subTabs.length; i++) ...[
                          if (subTabs[i].id == firstBottomTabId &&
                              !compactSidebar)
                            const Spacer(),
                          _SidebarTabButton(
                            key: Key('profile_nav_${subTabs[i].id}'),
                            tab: subTabs[i],
                            isActive: activeTabId == subTabs[i].id,
                            verticalPad: itemVerticalPad,
                            colors: colors,
                            strings: strings,
                            badgeCount: subTabs[i].id == 'p-sessions'
                                ? activeSessionsCount
                                : null,
                            showAlertBadge:
                                subTabs[i].id == 'p-about' && isTermsUnsigned,
                            onTap: subTabs[i].isEnabled
                                ? () => _handleSubTabSwitch(subTabs[i].id)
                                : null,
                          ),
                          if (i < subTabs.length - 1 &&
                              subTabs[i + 1].id != firstBottomTabId)
                            SizedBox(height: compactSidebar ? 1 : 3),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Left Content Area (Scrollable Content + Sticky Save Bar) ──
              Expanded(
                child: Container(
                  color: colors.bg,
                  child: Column(
                    children: [
                      Expanded(
                        child: activeTabId == 'p-referral'
                            ? activeContent
                            : SingleChildScrollView(
                                key: ValueKey('profile_scroll_$activeTabId'),
                                controller: _scrollControllerFor(activeTabId),
                                physics: const BouncingScrollPhysics(),
                                child: activeContent,
                              ),
                      ),
                      if (isEditableTab)
                        _StickySaveBar(
                          colors: colors,
                          strings: strings,
                          onSave: () async {
                            final currentValues = ref
                                .read(appStateProvider)
                                .identityValues;
                            if (!_isIdentityValid(currentValues)) {
                              AppToast.showWarning(
                                context,
                                strings.idErrValidationSummary,
                              );
                              return;
                            }

                            final success = await ref
                                .read(appStateProvider.notifier)
                                .saveProfileToFirestore();
                            if (!context.mounted) return;
                            if (success) {
                              AppToast.showSuccess(
                                context,
                                strings.profileSavedToast,
                              );
                            } else {
                              AppToast.showError(
                                context,
                                strings.profileSaveErrorToast,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarTabButton extends StatelessWidget {
  final _SubTabMeta tab;
  final bool isActive;
  final double verticalPad;
  final AppColors colors;
  final AppStrings strings;
  final int? badgeCount;
  final bool showAlertBadge;
  final VoidCallback? onTap;

  const _SidebarTabButton({
    super.key,
    required this.tab,
    required this.isActive,
    required this.verticalPad,
    required this.colors,
    required this.strings,
    this.badgeCount,
    this.showAlertBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = tab.isEnabled;
    final effectiveIsActive = isActive && isEnabled;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.55,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: verticalPad, horizontal: 4),
          decoration: BoxDecoration(
            color: effectiveIsActive
                ? colors.pr.withValues(alpha: 0.08)
                : Colors.transparent,
            border: BorderDirectional(
              start: BorderSide(
                color: effectiveIsActive ? colors.pr : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tab.icon is FaIconData)
                      FaIcon(
                        tab.icon as FaIconData,
                        size: 18,
                        color: !isEnabled
                            ? colors.mu
                            : (effectiveIsActive ? colors.pr : colors.mu),
                      )
                    else
                      Icon(
                        tab.icon,
                        size: 18,
                        color: !isEnabled
                            ? colors.mu
                            : (effectiveIsActive ? colors.pr : colors.mu),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        fontWeight: effectiveIsActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: !isEnabled
                            ? colors.mu
                            : (effectiveIsActive ? colors.pr : colors.mu),
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tab.badgeText != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.mu.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: colors.bd.withValues(alpha: 0.8),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          tab.badgeText!,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: colors.mu,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                PositionedDirectional(
                  top: 0,
                  end: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.ok,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 14,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      strings.formatNumber(badgeCount!),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: colors.prt,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              if (showAlertBadge)
                PositionedDirectional(
                  top: 0,
                  end: 4,
                  child: Container(
                    key: const Key('sidebar_about_alert_badge'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickySaveBar extends ConsumerWidget {
  final AppColors colors;
  final AppStrings strings;
  final VoidCallback onSave;

  const _StickySaveBar({
    required this.colors,
    required this.strings,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (hasChanges, isSaving) = ref.watch(
      appStateProvider.select((s) => (s.hasUnsavedChanges, s.isSavingProfile)),
    );

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.sf,
        border: Border(top: BorderSide(color: colors.bd)),
      ),
      child: AppButton(
        isFullWidth: true,
        variant: AppButtonVariant.primary,
        size: AppButtonSize.md,
        icon: isSaving
            ? null
            : FaIcon(
                hasChanges
                    ? FontAwesomeIcons.floppyDisk
                    : FontAwesomeIcons.check,
                size: 14,
                color: hasChanges ? colors.prt : colors.mu,
              ),
        text: isSaving
            ? null
            : (hasChanges ? strings.saveChanges : strings.noChangesYet),
        onPressed: (hasChanges && !isSaving) ? onSave : null,
        child: isSaving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.prt,
                ),
              )
            : null,
      ),
    );
  }
}

class _SubTabMeta {
  final String id;
  final String label;
  final dynamic icon;
  final bool isEnabled;
  final String? badgeText;

  const _SubTabMeta(
    this.id,
    this.label,
    this.icon, {
    this.isEnabled = true,
    this.badgeText,
  });
}
