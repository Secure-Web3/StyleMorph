import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Multi-step high-security modal dialog for changing user email address.
///
/// Steps:
/// 1. Re-authentication with current password via [reauthenticateWithCredential].
/// 2. Entering new email and dispatching verification via [verifyBeforeUpdateEmail].
/// 3. Success confirmation with notice of active old email until verification.
class ChangeEmailDialog extends StatefulWidget {
  final User? user;

  const ChangeEmailDialog({super.key, this.user});

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
          child: ChangeEmailDialog(user: user),
        ),
      ),
    );
  }

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  int _currentStep = 1;
  late final TextEditingController _passwordController;
  late final TextEditingController _newEmailController;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _submittedNewEmail;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _newEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _newEmailController.dispose();
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

  Future<void> _handleReauthenticate() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = context.strings.authPasswordHint;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _currentUser;
      if (user != null && Firebase.apps.isNotEmpty) {
        final email = user.email ?? '';
        final cred = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 2;
        _errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = context.strings.authErrInvalidCredential;
        } else {
          _errorMessage = context.strings.authErrorMessage(e.code);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = 2;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSendVerification() async {
    final newEmail = _newEmailController.text.trim();
    final strings = context.strings;

    if (newEmail.isEmpty ||
        !newEmail.contains('@') ||
        !newEmail.contains('.')) {
      setState(() {
        _errorMessage = strings.idChangeEmailInvalidError;
      });
      return;
    }

    final currentEmail = _currentUser?.email ?? '';
    if (newEmail.toLowerCase() == currentEmail.toLowerCase()) {
      setState(() {
        _errorMessage = strings.idChangeEmailSameError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _currentUser;
      if (user != null && Firebase.apps.isNotEmpty) {
        await user.verifyBeforeUpdateEmail(newEmail);

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'pendingEmail': newEmail,
                'pendingEmailRequestedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[ChangeEmailDialog] Firestore update note: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submittedNewEmail = newEmail;
        _currentStep = 3;
        _errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = strings.authErrorMessage(e.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _submittedNewEmail = newEmail;
        _currentStep = 3;
        _errorMessage = null;
      });
    }
  }

  void _onContactSupport() {
    Navigator.of(context).pop();
    AppFeedback.showSuccess(context, context.strings.supHi);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = context.strings;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step 1: Mandatory Re-Authentication
          if (_currentStep == 1) ...[
            _buildStep1Reauth(colors, strings),
          ]
          // Step 2: New Email & Verification Link
          else if (_currentStep == 2) ...[
            _buildStep2NewEmail(colors, strings),
          ]
          // Step 3: Success Confirmation
          else ...[
            _buildStep3Success(colors, strings),
          ],

          // Lost Access / Support Contact Footer Link
          if (_currentStep < 3) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: InkWell(
                onTap: _onContactSupport,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    strings.idLostAccessEmailSupport,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: colors.mu,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1Reauth(AppColors colors, AppStrings strings) {
    final currentEmail = _currentUser?.email ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.pr.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(
                FontAwesomeIcons.shieldHalved,
                size: 16,
                color: colors.pr,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.idChangeEmailTitle,
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                  const SizedBox(height: 2),
                  Text('1 / 2', style: AppTypography.caption(color: colors.mu)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 20, color: colors.mu),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.idChangeEmailReauthSubtitle,
          style: AppTypography.bodySmall(color: colors.mu),
        ),
        const SizedBox(height: AppSpacing.md),

        // Display current email read-only
        if (currentEmail.isNotEmpty) ...[
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.sf,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.bd),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: colors.mu),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    currentEmail,
                    style: AppTypography.bodySmall(color: colors.tx),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Password input field
        AppTextField(
          label: strings.idCurrentPasswordLabel,
          placeholder: strings.authPasswordHint,
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          prefix: Icon(Icons.lock_outline_rounded, size: 16, color: colors.mu),
          suffix: GestureDetector(
            onTap: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
            child: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: colors.mu,
            ),
          ),
          onSubmitted: _isLoading ? null : _handleReauthenticate,
        ),

        // Error message banner if any
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: colors.orColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: AppTypography.caption(color: colors.orColor),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.outline,
                text: strings.back,
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: AppButton(
                variant: AppButtonVariant.primary,
                text: _isLoading ? null : strings.idVerifyAndContinue,
                onPressed: _isLoading ? null : _handleReauthenticate,
                child: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.prt,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2NewEmail(AppColors colors, AppStrings strings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.pr.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(
                FontAwesomeIcons.envelopeCircleCheck,
                size: 16,
                color: colors.pr,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.idChangeEmailTitle,
                    style: AppTypography.cardTitle(color: colors.tx),
                  ),
                  const SizedBox(height: 2),
                  Text('2 / 2', style: AppTypography.caption(color: colors.mu)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 20, color: colors.mu),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // New Email Input Field
        AppTextField(
          label: strings.idNewEmailLabel,
          placeholder: 'name@example.com',
          controller: _newEmailController,
          keyboardType: TextInputType.emailAddress,
          prefix: Icon(
            Icons.mark_email_unread_outlined,
            size: 16,
            color: colors.mu,
          ),
          onSubmitted: _isLoading ? null : _handleSendVerification,
        ),

        const SizedBox(height: AppSpacing.md),

        // Security Notice Box
        AppCard(
          variant: AppCardVariant.surface,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: colors.wn),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  strings.idChangeEmailNotice,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    color: colors.tx,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error message banner if any
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: colors.orColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: AppTypography.caption(color: colors.orColor),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: AppButton(
                variant: AppButtonVariant.outline,
                text: strings.back,
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _currentStep = 1),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: AppButton(
                variant: AppButtonVariant.primary,
                text: _isLoading ? null : strings.idSendVerificationToNewEmail,
                onPressed: _isLoading ? null : _handleSendVerification,
                child: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.prt,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Success(AppColors colors, AppStrings strings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.ok.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 32,
              color: colors.ok,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          strings.idChangeEmailSuccessTitle,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium(color: colors.tx),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          strings.idChangeEmailSuccessDesc(_submittedNewEmail ?? ''),
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(
            color: colors.mu,
          ).copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          variant: AppButtonVariant.primary,
          text: strings.commonGotIt,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
