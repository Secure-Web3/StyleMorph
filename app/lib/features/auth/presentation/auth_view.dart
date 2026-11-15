import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_text_field.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  bool _isAuthPage = false;
  bool _isBusiness = false;

  void _onLogin() {
    ref.read(appStateProvider.notifier).login();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final currentLang = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Top Navigation: Back Button, Language Selector, Theme buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_isAuthPage)
                        InkWell(
                          onTap: () => setState(() => _isAuthPage = false),
                          borderRadius: AppRadius.rFull,
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colors.sf,
                              borderRadius: AppRadius.rFull,
                              border: Border.all(color: colors.bd),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  size: 14,
                                  color: colors.tx,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  strings.back,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.tx,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Language selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.sf,
                              borderRadius: AppRadius.rFull,
                              border: Border.all(color: colors.bd),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: currentLang.code,
                                isDense: true,
                                icon: const Icon(Icons.arrow_drop_down, size: 16),
                                items: AppLanguage.supportedLanguages.map((l) {
                                  return DropdownMenuItem<String>(
                                    value: l.code,
                                    child: Text(
                                      l.nativeName,
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.tx,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (code) {
                                  if (code != null) {
                                    ref
                                        .read(localeProvider.notifier)
                                        .setLanguage(code);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),

                          // Theme cycle button
                          InkWell(
                            onTap: () =>
                                ref.read(themeProvider.notifier).cyclePalette(),
                            borderRadius: AppRadius.rFull,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: colors.sf,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.bd),
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.palette,
                                size: 13,
                                color: colors.tx,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),

                          // Dark mode toggle button
                          InkWell(
                            onTap: () =>
                                ref.read(themeProvider.notifier).toggleDark(),
                            borderRadius: AppRadius.rFull,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: colors.sf,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.bd),
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.circleHalfStroke,
                                size: 13,
                                color: colors.tx,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Content: Welcome or Auth Form
                  if (!_isAuthPage)
                    _buildWelcomeSection(colors, strings)
                  else
                    _buildAuthForm(colors, strings),

                  const Spacer(),

                  // Footer Copyright
                  Text(
                    '© 2026 StyleMorph',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.mu,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AppColors colors, AppStrings strings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppCard(
          padding: EdgeInsetsDirectional.all(AppSpacing.xxl),
          child: Center(child: AppLogo(size: 64)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          strings.appName,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings.sub,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.tx,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.desc,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: colors.mu,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          isFullWidth: true,
          icon: FaIcon(FontAwesomeIcons.solidUser, size: 14, color: colors.prt),
          text: strings.pers,
          onPressed: () {
            setState(() {
              _isAuthPage = true;
              _isBusiness = false;
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          isFullWidth: true,
          variant: AppButtonVariant.secondary,
          icon: FaIcon(FontAwesomeIcons.store, size: 14, color: colors.tx),
          text: strings.biz,
          onPressed: () {
            setState(() {
              _isAuthPage = true;
              _isBusiness = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAuthForm(AppColors colors, AppStrings strings) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isBusiness ? strings.bT : strings.pT,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.tx,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _isBusiness ? strings.bS : strings.pS,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: colors.mu,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: strings.acc,
            initialValue: 'sara.ahmadi@gmail.com',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: strings.pw,
            initialValue: '••••••••',
            obscureText: true,
          ),
          if (_isBusiness) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: strings.bid,
              placeholder: '10-digit ID',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            isFullWidth: true,
            text: strings.go,
            onPressed: _onLogin,
          ),
          if (!_isBusiness) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Divider(color: colors.bd)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    strings.orText,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: colors.mu,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colors.bd)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.secondary,
                    icon: FaIcon(FontAwesomeIcons.google,
                        size: 14, color: colors.tx),
                    text: 'Google',
                    onPressed: _onLogin,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.secondary,
                    icon:
                        FaIcon(FontAwesomeIcons.apple, size: 16, color: colors.tx),
                    text: 'Apple ID',
                    onPressed: _onLogin,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.reg,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.tx,
                ),
              ),
              Text(
                strings.forgot,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: colors.mu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
