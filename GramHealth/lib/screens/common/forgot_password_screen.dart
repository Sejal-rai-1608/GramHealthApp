import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/care_icon_button.dart';
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
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: error ? AppColors.emergency : AppColors.tealDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _reset() async {
    final email = _emailCtrl.text.trim();
    final np = _newPassCtrl.text;
    final cp = _confirmCtrl.text;
    if (email.isEmpty || np.isEmpty || cp.isEmpty) {
      _snack('Please fill in all fields.');
      return;
    }
    if (np.length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }
    if (np != cp) {
      _snack('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(emailOrPhone: email, newPassword: np);
      _snack('Password reset successful. Please sign in.', error: false);
      if (mounted) context.go('/login');
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Failed to reset password. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CareIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.go('/login'),
            tooltip: 'Back',
            iconSize: 18,
            size: 44,
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'Reset password',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.tealPale),
              ),
              child: const Icon(Icons.lock_reset_rounded, size: 28, color: AppColors.teal),
            ),
            const SizedBox(height: 14),
            Text(
              'Create a new password',
              style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your registered email or phone number and choose a new password.',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 18),
            CareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomInput(label: 'Email or phone', placeholder: 'Registered email or phone', controller: _emailCtrl),
                  CustomInput(
                    label: 'New password',
                    placeholder: 'At least 8 characters',
                    controller: _newPassCtrl,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.inkMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  CustomInput(
                    label: 'Confirm new password',
                    placeholder: 'Repeat new password',
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.teal)))
                  else
                    PrimaryButton(title: 'Reset password', onPress: _reset, width: double.infinity),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text('Back to sign in',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal)),
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
