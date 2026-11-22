import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/password_generator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Modal dialog for changing or setting account password via official Firebase Auth.
class ChangePasswordDialog extends StatefulWidget {
  final User? user;

  const ChangePasswordDialog({super.key, this.user});

  static Future<void> show(BuildContext context, {User? user}) {
    final colors = context.colors;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: colors.sf,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.bd),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ChangePasswordDialog(user: user),
        ),
      ),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;
  bool _isResetEmailSending = false;
  String? _errorMessage;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  User? get _currentUser {
    if (widget.user != null) return widget.user;
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseAuth.instance.currentUser;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool get _isGoogleOnlyUser {
    final user = _currentUser;
    if (user == null) return false;
    final hasGoogle = user.providerData.any(
      (p) => p.providerId == 'google.com',
    );
    final hasPassword = user.providerData.any(
      (p) => p.providerId == 'password',
    );
    return hasGoogle && !hasPassword;
  }

  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[a-zA-Z]').hasMatch(password)) {
      score++;
    }
    if (password.length >= 10 && RegExp(r'[!@#\$&*~_.-]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  Future<void> _handlePasswordUpdate() async {
    final strings = context.strings;
    final currentPw = _currentPasswordController.text.trim();
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
      _errorMessage = null;
    });

    bool hasError = false;
    if (currentPw.isEmpty) {
      _currentPasswordError = strings.cpCurrentPasswordPlaceholder;
      hasError = true;
    }
    if (newPw.length < 8) {
      _newPasswordError = strings.cpErrMinLength;
      hasError = true;
    }
    if (newPw != confirmPw) {
      _confirmPasswordError = strings.cpErrMismatch;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    final user = _currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _errorMessage = strings.profileSaveErrorToast;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPw,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update password
      await user.updatePassword(newPw);

      if (!mounted) return;
      AppFeedback.showSuccess(context, strings.cpSuccessToast);
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _currentPasswordError = strings.cpErrWrongPassword;
        } else if (e.code == 'weak-password') {
          _newPasswordError = strings.cpErrMinLength;
        } else {
          _errorMessage = strings.authErrorMessage(e.code);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleSendResetEmail() async {
    final strings = context.strings;
    final user = _currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) return;

    setState(() {
      _isResetEmailSending = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _isResetEmailSending = false);
      AppFeedback.showSuccess(context, strings.cpResetEmailSent);
      if (_isGoogleOnlyUser) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResetEmailSending = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;
    final isGoogle = _isGoogleOnlyUser;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.pr.withValues(alpha: 0.1),
                      borderRadius: AppRadius.rMd,
                    ),
                    alignment: Alignment.center,
                    child: FaIcon(
                      isGoogle ? FontAwesomeIcons.google : FontAwesomeIcons.key,
                      size: 14,
                      color: colors.pr,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    strings.cpTitle,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.tx,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                color: colors.mu,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isGoogle ? strings.cpGoogleUserNote : strings.cpSubtitle,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: colors.mu,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Error banner if any
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.orColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.rMd,
                border: Border.all(
                  color: colors.orColor.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: colors.orColor),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        color: colors.orColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Google-Only Flow vs Email/Password Flow
          if (isGoogle) ...[
            AppButton(
              variant: AppButtonVariant.primary,
              icon: _isResetEmailSending
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.prt,
                      ),
                    )
                  : const FaIcon(FontAwesomeIcons.envelope, size: 12),
              text: _isResetEmailSending ? null : strings.cpSendSetupEmail,
              onPressed: _isResetEmailSending ? null : _handleSendResetEmail,
            ),
          ] else ...[
            // Current Password
            AppTextField(
              label: strings.cpCurrentPassword,
              placeholder: strings.cpCurrentPasswordPlaceholder,
              controller: _currentPasswordController,
              errorText: _currentPasswordError,
              obscureText: !_isCurrentPasswordVisible,
              onChanged: (_) {
                if (_currentPasswordError != null) {
                  setState(() => _currentPasswordError = null);
                }
              },
              suffix: IconButton(
                icon: Icon(
                  _isCurrentPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 16,
                  color: colors.mu,
                ),
                onPressed: () {
                  setState(() {
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // New Password + Strength Indicator
            AppTextField(
              label: strings.cpNewPassword,
              placeholder: strings.cpNewPasswordPlaceholder,
              controller: _newPasswordController,
              errorText: _newPasswordError,
              obscureText: !_isNewPasswordVisible,
              onGeneratePassword: () {
                final generated = generateStrongPassword(12);
                setState(() {
                  _newPasswordController.text = generated;
                  _confirmPasswordController.text = generated;
                  _isNewPasswordVisible = true;
                  _isConfirmPasswordVisible = true;
                  _newPasswordError = null;
                  _confirmPasswordError = null;
                });
                AppFeedback.showSuccess(
                  context,
                  strings.passwordGeneratedToast,
                );
              },
              generatePasswordTooltip: strings.authGeneratePasswordTooltip,
              onChanged: (_) {
                setState(() {
                  if (_newPasswordController.text.isNotEmpty &&
                      _newPasswordController.text.length < 8) {
                    _newPasswordError = strings.cpErrMinLength;
                  } else {
                    _newPasswordError = null;
                  }
                  if (_confirmPasswordError != null &&
                      _confirmPasswordController.text ==
                          _newPasswordController.text) {
                    _confirmPasswordError = null;
                  }
                });
              },
              suffix: IconButton(
                icon: Icon(
                  _isNewPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 16,
                  color: colors.mu,
                ),
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
            ),
            if (_newPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildStrengthBar(colors),
            ],
            const SizedBox(height: AppSpacing.sm),

            // Confirm New Password
            AppTextField(
              label: strings.cpConfirmPassword,
              placeholder: strings.cpConfirmPasswordPlaceholder,
              controller: _confirmPasswordController,
              errorText: _confirmPasswordError,
              obscureText: !_isConfirmPasswordVisible,
              onChanged: (_) {
                setState(() {
                  if (_confirmPasswordController.text.isNotEmpty &&
                      _confirmPasswordController.text.length < 8) {
                    _confirmPasswordError = strings.cpErrMinLength;
                  } else if (_confirmPasswordController.text !=
                      _newPasswordController.text) {
                    _confirmPasswordError = strings.cpErrMismatch;
                  } else {
                    _confirmPasswordError = null;
                  }
                });
              },
              suffix: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 16,
                  color: colors.mu,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // "Forgot current password? Send reset link to email" link
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                onTap: _isResetEmailSending ? null : _handleSendResetEmail,
                borderRadius: AppRadius.rSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _isResetEmailSending ? '...' : strings.cpForgotPasswordLink,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: colors.pr,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.primary,
                    icon: _isLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.prt,
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.check, size: 12),
                    text: _isLoading ? null : strings.cpSubmit,
                    onPressed: _isLoading ? null : _handlePasswordUpdate,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  text: strings.dialogCancel,
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStrengthBar(AppColors colors) {
    final strength = _calculateStrength(_newPasswordController.text);
    Color barColor;
    if (strength <= 1) {
      barColor = colors.orColor;
    } else if (strength == 2) {
      barColor = colors.wn;
    } else {
      barColor = colors.ok;
    }

    return Row(
      children: List.generate(3, (index) {
        final isActive = index < strength;
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? barColor : colors.bd,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
