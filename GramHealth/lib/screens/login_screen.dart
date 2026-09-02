import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_input.dart';
import '../widgets/language_selector_modal.dart';
import '../widgets/primary_button.dart';
import '../services/api_client.dart';
import '../utils/auth_guard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading     = false;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateByRole(String role) {
    AuthGuard.onLogin(role);
    switch (role.toLowerCase()) {
      case 'admin':
        context.go('/admin/dashboard');
        break;
      case 'doctor':
        context.go('/doctor/dashboard');
        break;
      default:
        context.go('/main/home');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.login(email, password);
      final role = (user['role'] as String? ?? 'PATIENT').toLowerCase();
      _navigateByRole(role);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    final name     = _nameCtrl.text.trim();
    final phone    = _phoneCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: _selectedRole,
      );
      // After registration, log in automatically
      final user = await AuthService.login(email, password);
      final role = (user['role'] as String? ?? 'PATIENT').toLowerCase();
      if (role == 'doctor') {
        // Send new doctors to the onboarding screen to fill professional details
        if (mounted) {
          AuthGuard.onLogin(role);
          context.go('/doctor/onboarding');
        }
      } else {
        _navigateByRole(role);
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleContinue() {
    if (_isRegistering) {
      _handleRegister();
    } else {
      _handleLogin();
    }
  }

  // ── Role Card ─────────────────────────────────────────────────────────────

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
              Icon(icon,
                  color: isSelected ? Colors.white : AppColors.textDark,
                  size: 24),
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

  // ── Build ─────────────────────────────────────────────────────────────────

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
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.white),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Language switcher
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => showLanguageSelector(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language,
                                size: 18, color: AppColors.textDark),
                            const SizedBox(width: 6),
                            Text(
                              context.currentLanguage.nativeName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_box_outlined,
                        size: 32, color: AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _isRegistering
                        ? context.tr('create_account')
                        : context.tr('welcome_back'),
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
                        color: AppColors.textDark.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Form card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Role selection (only for registration)
                        if (_isRegistering) ...[
                          Text(
                            'Select your role:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  AppColors.textDark.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildRoleCard(
                                  'patient', Icons.person_outline, 'User'),
                              _buildRoleCard('doctor',
                                  Icons.local_hospital_outlined, 'Doctor'),
                              _buildRoleCard(
                                  'admin',
                                  Icons.admin_panel_settings_outlined,
                                  'Admin'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          CustomInput(
                            label: 'Full Name',
                            placeholder: 'Enter your full name',
                            controller: _nameCtrl,
                          ),
                          CustomInput(
                            label: 'Phone',
                            placeholder: 'Enter your phone number',
                            controller: _phoneCtrl,
                          ),
                        ],

                        CustomInput(
                          label: _isRegistering ? 'Email' : 'Email or Phone',
                          placeholder: _isRegistering ? 'Enter your email address' : 'Enter your email or phone',
                          controller: _emailCtrl,
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

                        // Submit button
                        _isLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(),
                              )
                            : PrimaryButton(
                                title: _isRegistering
                                    ? context.tr('register_btn')
                                    : context.tr('continue_btn'),
                                onPress: _handleContinue,
                                width: double.infinity,
                              ),

                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => setState(
                              () => _isRegistering = !_isRegistering),
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
