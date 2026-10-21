import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
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
    final email = _emailCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (email.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showNotification('Please fill in all fields.');
      return;
    }

    if (newPassword.length < 6) {
      _showNotification('Password must be at least 6 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showNotification('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.resetPassword(
        emailOrPhone: email,
        newPassword: newPassword,
      );

      _showNotification('Password reset successfully! Please log in.', isError: false);
      if (mounted) {
        context.go('/login');
      }
    } on ApiException catch (e) {
      _showNotification(e.message);
    } catch (e) {
      _showNotification('Failed to reset password. Please check your connection.');
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
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset, size: 32, color: AppColors.primaryAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Forgot Your Password?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your registered email or phone number and set a new password for your account.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CustomInput(
                    label: 'Email or Phone Number',
                    placeholder: 'Enter registered email or phone',
                    controller: _emailCtrl,
                  ),
                  CustomInput(
                    label: 'New Password',
                    placeholder: 'Enter your new password',
                    controller: _newPasswordCtrl,
                    obscureText: true,
                  ),
                  CustomInput(
                    label: 'Confirm New Password',
                    placeholder: 'Re-enter your new password',
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                          title: 'Reset Password',
                          onPress: _handleResetPassword,
                          width: double.infinity,
                        ),

                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Back to Login',
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
