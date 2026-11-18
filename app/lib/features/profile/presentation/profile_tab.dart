import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import 'widgets/ai_dna_sub_tab.dart';
import 'widgets/gallery_sub_tab.dart';
import 'widgets/identity_sub_tab.dart';
import 'widgets/persona_sub_tab.dart';
import 'widgets/referral_sub_tab.dart';
import 'widgets/sessions_sub_tab.dart';
import 'widgets/settings_sub_tab.dart';
import 'widgets/wallet_sub_tab.dart';

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(appStateProvider.notifier).loadProfileFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final appState = ref.watch(appStateProvider);
    final activeTabId = appState.currentProfileTab;
    final isEditableTab = _editableTabs.contains(activeTabId);

    final subTabs = [
      _SubTabMeta('p-identity', strings.tIdent, FontAwesomeIcons.idCard),
      _SubTabMeta('p-gallery', strings.tGal, FontAwesomeIcons.images),
      _SubTabMeta('p-ai', strings.tAi, FontAwesomeIcons.dna),
      _SubTabMeta('p-wallet', strings.tWal, FontAwesomeIcons.wallet),
      _SubTabMeta('p-referral', strings.tRef, FontAwesomeIcons.gift),
      _SubTabMeta(
        'p-companion',
        strings.tComp,
        FontAwesomeIcons.wandMagicSparkles,
      ),
      _SubTabMeta('p-sessions', strings.tSess, LucideIcons.monitorSmartphone),
      _SubTabMeta('p-settings', strings.tSet, FontAwesomeIcons.sliders),
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
        activeContent = const SessionsSubTab();
        break;
      case 'p-settings':
        activeContent = const SettingsSubTab();
        break;
      default:
        activeContent = const IdentitySubTab();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactSidebar = constraints.maxHeight < 460;
        final itemVerticalPad = compactSidebar ? 4.0 : 8.0;

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
                  border: BorderDirectional(
                    end: BorderSide(color: colors.bd),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (int i = 0; i < subTabs.length; i++) ...[
                          if (subTabs[i].id == 'p-sessions' && !compactSidebar)
                            const Spacer(),
                          _SidebarTabButton(
                            tab: subTabs[i],
                            isActive: activeTabId == subTabs[i].id,
                            verticalPad: itemVerticalPad,
                            colors: colors,
                            onTap: () {
                              ref
                                  .read(appStateProvider.notifier)
                                  .switchProfileTab(subTabs[i].id);
                            },
                          ),
                          if (i < subTabs.length - 1 &&
                              subTabs[i + 1].id != 'p-sessions')
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: activeContent,
                        ),
                      ),
                      if (isEditableTab)
                        _StickySaveBar(
                          colors: colors,
                          strings: strings,
                          hasChanges: appState.hasUnsavedProfileChanges,
                          isSaving: appState.isSavingProfile,
                          onSave: () async {
                            final success = await ref
                                .read(appStateProvider.notifier)
                                .saveProfileToFirestore();
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    strings.profileSavedToast,
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  backgroundColor: colors.ok,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'خطا در ذخیره تغییرات در سرور. لطفا مجددا تلاش کنید.',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  backgroundColor: colors.orColor,
                                  duration: const Duration(seconds: 3),
                                ),
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
  final VoidCallback onTap;

  const _SidebarTabButton({
    required this.tab,
    required this.isActive,
    required this.verticalPad,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: verticalPad, horizontal: 4),
        decoration: BoxDecoration(
          color:
              isActive ? colors.pr.withValues(alpha: 0.08) : Colors.transparent,
          border: BorderDirectional(
            start: BorderSide(
              color: isActive ? colors.pr : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tab.icon is FaIconData)
              FaIcon(
                tab.icon as FaIconData,
                size: 18,
                color: isActive ? colors.pr : colors.mu,
              )
            else
              Icon(
                tab.icon,
                size: 18,
                color: isActive ? colors.pr : colors.mu,
              ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? colors.pr : colors.mu,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  final AppColors colors;
  final AppStrings strings;
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onSave;

  const _StickySaveBar({
    required this.colors,
    required this.strings,
    required this.hasChanges,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
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
                hasChanges ? FontAwesomeIcons.floppyDisk : FontAwesomeIcons.check,
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

  const _SubTabMeta(this.id, this.label, this.icon);
}
