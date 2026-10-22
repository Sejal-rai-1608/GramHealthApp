import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailPhoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailPhoneCtrl.dispose();
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

  Future<void> _handleSendResetCode() async {
    final emailPhone = _emailPhoneCtrl.text.trim();

    if (emailPhone.isEmpty) {
      _showNotification('Please enter your email or phone number.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('[ForgotPassword] Calling forgotPassword API with: $emailPhone');
      await AuthService.forgotPassword(emailOrPhone: emailPhone);
      print('[ForgotPassword] API call succeeded');

      _showNotification('Reset code sent! Please check your email/SMS.', isError: false);
      
      if (mounted) {
        print('[ForgotPassword] Navigating to /reset-password');
        context.push('/reset-password', extra: {
          'emailOrPhone': emailPhone,
        });
      }
    } on ApiException catch (e) {
      print('[ForgotPassword] ApiException: ${e.message} (${e.statusCode})');
      _showNotification(e.message);
    } catch (e) {
      print('[ForgotPassword] Unexpected error: $e');
      _showNotification('Failed to send reset code. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 40, color: AppColors.primaryAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your registered email or phone number. We\'ll send you a verification code to reset your password.',
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
                    label: 'Email or Phone Number',
                    placeholder: 'Enter registered email or phone',
                    controller: _emailPhoneCtrl,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 24),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : PrimaryButton(
                          title: 'Send Reset Code',
                          onPress: _handleSendResetCode,
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