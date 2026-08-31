import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_input.dart';
import '../widgets/language_selector_modal.dart';
import '../widgets/primary_button.dart';
import '../utils/auth_guard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isRegistering = false;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _handleContinue() {
    AuthService.currentUserRole = _selectedRole;
    if (_selectedRole == 'admin') {
      context.go('/admin/dashboard');
    } else if (_selectedRole == 'doctor') {
      context.go('/doctor/dashboard');
    } else {
      context.go('/main/home');
    }
  }

  Widget _buildRoleCard(String role, IconData icon, String title) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryAccent : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textDark,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1576091160550-217359f4ecf8?auto=format&fit=crop&q=80&w=2070',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.85),
              colorBlendMode: BlendMode.lighten,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Top bar with language switcher
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => showLanguageSelector(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language, size: 18, color: AppColors.textDark),
                            const SizedBox(width: 6),
                            Text(
                              context.currentLanguage.nativeName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Logo icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_box_outlined,
                      size: 32,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _isRegistering ? context.tr('create_account') : context.tr('welcome_back'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegistering
                        ? context.tr('register_desc')
                        : context.tr('signin_desc'),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Card with form
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Role Selection
                        Text(
                          'Select your role:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildRoleCard('patient', Icons.person_outline, 'User'),
                            _buildRoleCard('doctor', Icons.local_hospital_outlined, 'Doctor'),
                            _buildRoleCard('admin', Icons.admin_panel_settings_outlined, 'Admin'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        CustomInput(
                          label: context.tr('username'),
                          placeholder: context.tr('enter_username'),
                          controller: _usernameCtrl,
                        ),
                        CustomInput(
                          label: context.tr('password'),
                          placeholder: context.tr('enter_password'),
                          controller: _passwordCtrl,
                          obscureText: true,
                        ),
                        if (_isRegistering)
                          CustomInput(
                            label: context.tr('confirm_password'),
                            placeholder: context.tr('repeat_password'),
                            controller: _confirmCtrl,
                            obscureText: true,
                          ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          title: _isRegistering ? context.tr('register_btn') : context.tr('continue_btn'),
                          onPress: _handleContinue,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isRegistering = !_isRegistering),
                          child: Text(
                            _isRegistering
                                ? context.tr('already_have_account')
                                : context.tr('register_new_account'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textDark,
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
          ),
        ],
      ),
    );
  }
}
