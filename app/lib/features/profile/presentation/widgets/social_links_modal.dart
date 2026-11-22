import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_modal.dart';
import '../../../../core/widgets/app_toast.dart';
import 'about_actions.dart';

class SocialLinkItem {
  final String name;
  final String handle;
  final String url;
  final FaIconData icon;

  const SocialLinkItem({
    required this.name,
    required this.handle,
    required this.url,
    required this.icon,
  });
}

class SocialLinksModal extends StatelessWidget {
  const SocialLinksModal({super.key});

  static Future<void> show(BuildContext context) {
    return AppModal.showSheet(
      context: context,
      child: const SocialLinksModal(),
    );
  }

  void _handleItemTap(BuildContext context, SocialLinkItem item) {
    if (kIsWeb) {
      openExternalUrl(item.url);
    } else {
      Clipboard.setData(ClipboardData(text: item.url));
      final strings = context.strings;
      AppToast.showSuccess(
        context,
        '${item.name} ${strings.aboutLinkCopied}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final items = [
      SocialLinkItem(
        name: 'Instagram',
        handle: '@stylemorph.official',
        url: 'https://www.instagram.com/stylemorph.official',
        icon: FontAwesomeIcons.instagram,
      ),
      SocialLinkItem(
        name: 'TikTok',
        handle: '@stylemorph.official',
        url: 'https://www.tiktok.com/@stylemorph.official',
        icon: FontAwesomeIcons.tiktok,
      ),
      SocialLinkItem(
        name: strings.aboutTelegramOfficial,
        handle: '@StyleMorph_official',
        url: 'https://t.me/StyleMorph_official',
        icon: FontAwesomeIcons.telegram,
      ),
      SocialLinkItem(
        name: strings.aboutTelegramMain,
        handle: '@StyleMorph',
        url: 'https://t.me/StyleMorph',
        icon: FontAwesomeIcons.telegram,
      ),
      SocialLinkItem(
        name: strings.aboutTelegramCommunity,
        handle: '@StyleMorph_community',
        url: 'https://t.me/StyleMorph_community',
        icon: FontAwesomeIcons.telegram,
      ),
      SocialLinkItem(
        name: strings.aboutTelegramBot,
        handle: '@stylemorph_bot',
        url: 'https://t.me/stylemorph_bot',
        icon: FontAwesomeIcons.robot,
      ),
      SocialLinkItem(
        name: 'X (Twitter)',
        handle: '@StyleMorph',
        url: 'https://x.com/StyleMorph',
        icon: FontAwesomeIcons.xTwitter,
      ),
      SocialLinkItem(
        name: 'Threads',
        handle: '@stylemorph.official',
        url: 'https://www.threads.com/@stylemorph.official',
        icon: FontAwesomeIcons.threads,
      ),
      SocialLinkItem(
        name: 'Pinterest',
        handle: '@StyleMorph_studio',
        url: 'https://www.pinterest.com/StyleMorph_studio/',
        icon: FontAwesomeIcons.pinterest,
      ),
      SocialLinkItem(
        name: 'Snapchat',
        handle: '@stylemorph',
        url: 'https://www.snapchat.com/add/stylemorph',
        icon: FontAwesomeIcons.snapchat,
      ),
      SocialLinkItem(
        name: 'Facebook',
        handle: '@StyleMorph',
        url: 'https://www.facebook.com/share/18kdd8hc3s/',
        icon: FontAwesomeIcons.facebook,
      ),
      SocialLinkItem(
        name: 'Reddit',
        handle: 'u/StyleMorph_official',
        url: 'https://www.reddit.com/u/StyleMorph_official',
        icon: FontAwesomeIcons.reddit,
      ),
      SocialLinkItem(
        name: 'Bluesky',
        handle: '@stylemorph.bsky.social',
        url: 'https://bsky.app/profile/stylemorph.bsky.social',
        icon: FontAwesomeIcons.bluesky,
      ),
    ];

    return AppBottomSheetShell(
      title: strings.aboutSocialMediaLabel,
      titleLeading: FaIcon(
        FontAwesomeIcons.shareNodes,
        size: 16,
        color: colors.prt,
      ),
      scrollable: false,
      contentPadding: EdgeInsetsDirectional.zero,
      bottomBar: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: AppButton(
          variant: AppButtonVariant.outline,
          isFullWidth: true,
          text: strings.aboutClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Divider(color: colors.bd.withValues(alpha: 0.6), height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => _handleItemTap(context, item),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: FaIcon(
                        item.icon,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.tx,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: () => _handleItemTap(context, item),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.handle,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 11,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
