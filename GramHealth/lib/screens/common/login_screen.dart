import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/language_selector_modal.dart';
import '../../widgets/primary_button.dart';
import '../../services/api_client.dart';
import '../../utils/auth_guard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _obscurePass = true;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: error ? AppColors.emergency : AppColors.tealDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
        context.go('/doctor/requests');
        break;
      case 'pharmacy':
        context.go('/pharmacy/dashboard');
        break;
      default:
        context.go('/main/home');
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter your email and password.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.login(email, password);
      final role = (user['role'] as String? ?? 'PATIENT').toLowerCase();
      _navigateByRole(role);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || (e.statusCode == 400 && e.message.toLowerCase().contains('invalid'))) {
        _snack('Invalid email or password.');
      } else if (e.statusCode == 503) {
        _snack('Backend unreachable. Check your connection.');
      } else if (e.statusCode == 504) {
        _snack('Connection timed out.');
      } else {
        _snack(e.message);
      }
    } catch (e) {
      final s = e.toString().toLowerCase();
      if (s.contains('socketexception') || s.contains('connection refused') || s.contains('failed to fetch')) {
        _snack('Backend unreachable. Check your connection.');
      } else {
        _snack('Login failed: ${e.toString().replaceAll("Exception: ", "")}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || pass.isEmpty) {
      _snack('Please fill in all required fields.');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _snack('Please enter a valid email address.');
      return;
    }
    if (pass.length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }
    if (pass != confirm) {
      _snack('Passwords do not match.');
      return;
    }

    String? address;
    double? lat;
    double? lng;

    if (_selectedRole == 'pharmacy') {
      address = _addressCtrl.text.trim();
      if (address.isEmpty) {
        _snack('Please enter the pharmacy address.');
        return;
      }
      setState(() => _isLoading = true);
      try {
        final locs = await geocoding.Geocoding().locationFromAddress(address);
        if (locs.isNotEmpty) {
          lat = locs.first.latitude;
          lng = locs.first.longitude;
        }
      } catch (_) {
        setState(() => _isLoading = false);
        _snack('Could not locate that address. Try a different one.');
        return;
      }
      if (mounted) setState(() => _isLoading = false);
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: pass,
        role: _selectedRole,
        address: address,
        latitude: lat,
        longitude: lng,
      );
      final user = await AuthService.login(email, pass);
      final role = (user['role'] as String? ?? 'PATIENT').toLowerCase();
      if (!mounted) return;
      if (role == 'doctor') {
        AuthGuard.onLogin(role);
        context.go('/doctor/onboarding');
      } else {
        _navigateByRole(role);
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Network error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/onboarding'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showLanguageSelector(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, size: 14, color: AppColors.teal),
                          const SizedBox(width: 6),
                          Text(
                            context.currentLanguage.nativeName,
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Heading — one display, calm hierarchy
              Text(
                _isRegistering
                    ? context.tr('create_account')
                    : context.tr('welcome_back'),
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegistering
                    ? 'Choose your role and fill in the details below.'
                    : 'Sign in to continue your care journey.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),

              // Form — single CareCard, no nested cards
              CareCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isRegistering) ...[
                      Text(
                        'I am a',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _roleChip('patient', Icons.person_outline_rounded, 'Patient'),
                          const SizedBox(width: 8),
                          _roleChip('doctor', Icons.medical_services_outlined, 'Doctor'),
                          const SizedBox(width: 8),
                          _roleChip('pharmacy', Icons.local_pharmacy_outlined, 'Pharmacy'),
                          const SizedBox(width: 8),
                          _roleChip('admin', Icons.shield_outlined, 'Admin'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CustomInput(label: 'Full name', placeholder: 'Enter your full name', controller: _nameCtrl),
                      CustomInput(label: 'Phone', placeholder: '10-digit mobile number', controller: _phoneCtrl, keyboardType: TextInputType.phone),
                      if (_selectedRole == 'pharmacy')
                        CustomInput(label: 'Pharmacy address', placeholder: 'Street, area, city', controller: _addressCtrl),
                    ],
                    CustomInput(
                      label: _isRegistering ? 'Email' : 'Email or phone',
                      placeholder: _isRegistering ? 'name@example.com' : 'Email or phone number',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    CustomInput(
                      label: 'Password',
                      placeholder: 'At least 8 characters',
                      controller: _passwordCtrl,
                      obscureText: _obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18, color: AppColors.inkMuted),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    if (!_isRegistering)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () => context.go('/forgot-password'),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal),
                            ),
                          ),
                        ),
                      ),
                    if (_isRegistering)
                      CustomInput(
                        label: 'Confirm password',
                        placeholder: 'Repeat password',
                        controller: _confirmCtrl,
                        obscureText: _obscurePass,
                      ),
                    const SizedBox(height: 6),
                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 14), child: CircularProgressIndicator(color: AppColors.teal)))
                    else
                      PrimaryButton(
                        title: _isRegistering ? 'Create account' : 'Continue',
                        onPress: _isRegistering ? _handleRegister : _handleLogin,
                        width: double.infinity,
                      ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isRegistering = !_isRegistering),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
                            children: [
                              TextSpan(text: _isRegistering ? 'Already have an account? ' : "Don't have an account? "),
                              TextSpan(
                                text: _isRegistering ? 'Sign in' : 'Create one',
                                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.teal),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Trust footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.inkFaint),
                  const SizedBox(width: 6),
                  Text(
                    'Your data is protected and stored securely.',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkFaint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String value, IconData icon, String label) {
    final selected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: AppMotion.state,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: selected ? AppColors.ink : AppColors.borderLight, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppColors.inkMuted),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
