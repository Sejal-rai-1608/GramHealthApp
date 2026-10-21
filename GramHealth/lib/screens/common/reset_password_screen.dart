import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String emailOrPhone;

  const ResetPasswordScreen({super.key, required this.emailOrPhone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final otp = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showNotification('Please fill in all fields.');
      return;
    }

    if (otp.length != 6) {
      _showNotification('Please enter the 6-digit code.');
      return;
    }

    if (newPassword.length < 8) {
      _showNotification('Password must be at least 8 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showNotification('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.resetPasswordWithToken(
        emailOrPhone: widget.emailOrPhone,
        otp: otp,
        newPassword: newPassword,
      );

      _showNotification('Password reset successfully! Please log in.', isError: false);
      if (mounted) {
        context.go('/login');
      }
    } on ApiException catch (e) {
      _showNotification(e.message);
    } catch (e) {
      _showNotification('Failed to reset password. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/forgot-password'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_outlined, size: 40, color: AppColors.primaryAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a 6-digit code to your registered contact. Enter it below to reset your password.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CustomInput(
                    label: '6-Digit Verification Code',
                    placeholder: 'Enter 6-digit code',
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    label: 'New Password',
                    placeholder: 'Enter new password (min 8 chars)',
                    controller: _newPasswordCtrl,
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomInput(
                    label: 'Confirm New Password',
                    placeholder: 'Re-enter new password',
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirmPassword,
                  ),
                  const SizedBox(height: 24),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                          title: 'Reset Password',
                          onPress: _handleResetPassword,
                          width: double.infinity,
                        ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/forgot-password'),
                    child: const Text(
                      'Back to Forgot Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}