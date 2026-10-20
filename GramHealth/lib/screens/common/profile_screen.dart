import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/language_selector_modal.dart';
import '../../utils/auth_guard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;

  String _name = '';
  String _email = '';
  String _address = '';
  String _phoneNumber = '';
  String _age = '';
  String _gender = '';
  String _bloodGroup = '';
  String _pinCode = '';
  String _abhaId = '';

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _pinCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _abhaCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _pinCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _abhaCtrl = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _name = user['name'] as String? ?? '';
        _email = user['email'] as String? ?? '';
        _phoneNumber = user['phone'] as String? ?? '';
        _address = user['address'] as String? ?? '';
        _age = user['age']?.toString() ?? '';
        _gender = user['gender'] as String? ?? '';
        _bloodGroup = user['bloodGroup'] as String? ?? '';
        _pinCode = user['pinCode'] as String? ?? '';
        _abhaId = user['abhaId'] as String? ?? '';
        _isLoading = false;
        _nameCtrl.text = _name;
        _phoneCtrl.text = _phoneNumber;
        _ageCtrl.text = _age;
        _pinCtrl.text = _pinCode;
        _addressCtrl.text = _address;
        _abhaCtrl.text = _abhaId;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _pinCtrl.dispose();
    _addressCtrl.dispose();
    _abhaCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    setState(() {
      _name = _nameCtrl.text;
      _phoneNumber = _phoneCtrl.text;
      _age = _ageCtrl.text;
      _pinCode = _pinCtrl.text;
      _address = _addressCtrl.text;
      _abhaId = _abhaCtrl.text;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppColors.tealDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.ground, body: const Center(child: CircularProgressIndicator(color: AppColors.teal)));
    }
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            // Avatar + name
            Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                        style: GoogleFonts.manrope(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_name.isEmpty ? '—' : _name,
                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2)),
                const SizedBox(height: 3),
                Text(_address.isEmpty ? _email : _address,
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkMuted)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isEditing ? _handleSave : () => setState(() => _isEditing = true),
                    icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined, size: 16),
                    label: Text(_isEditing ? context.tr('save_changes') : context.tr('edit_profile'),
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isEditing ? AppColors.teal : AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.pill)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info
            CareCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _infoRow(Icons.mail_outline_rounded, 'Email', _email.isEmpty ? '—' : _email),
                  _divider(),
                  _infoRow(Icons.phone_outlined, context.tr('phone_number'), _phoneNumber.isEmpty ? '—' : _phoneNumber),
                  _divider(),
                  _infoRow(Icons.calendar_today_outlined, context.tr('age_gender'), () {
                    final parts = [if (_age.isNotEmpty) '$_age yrs', if (_gender.isNotEmpty) _gender];
                    return parts.isEmpty ? '—' : parts.join('  •  ');
                  }()),
                  _divider(),
                  _infoRow(Icons.location_on_outlined, context.tr('pin_code'), _pinCode.isEmpty ? '—' : _pinCode),
                  _divider(),
                  _infoRow(Icons.water_drop_outlined, context.tr('blood_group'), _bloodGroup.isEmpty ? '—' : _bloodGroup,
                      iconColor: AppColors.coral),
                  _divider(),
                  _infoRow(Icons.health_and_safety_outlined, 'ABHA ID', _abhaId.isEmpty ? '—' : _abhaId, iconColor: AppColors.teal),
                ],
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('edit_profile'), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 14),
                    _field(context.tr('username'), _nameCtrl, Icons.person_outline_rounded),
                    _field(context.tr('phone_number'), _phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
                    Row(
                      children: [
                        Expanded(child: _field(context.tr('age_gender'), _ageCtrl, null, type: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(context.tr('pin_code'), _pinCtrl, null, type: TextInputType.number)),
                      ],
                    ),
                    _field(context.tr('address_village'), _addressCtrl, Icons.place_outlined),
                    _field('ABHA ID (optional)', _abhaCtrl, Icons.health_and_safety_outlined),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _handleSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                          elevation: 0,
                        ),
                        child: Text(context.tr('save_changes'), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(context.tr('app_settings'),
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.1)),
            ),
            const SizedBox(height: 10),
            CareCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _settingRow(Icons.translate_rounded, '${context.tr('language')} — ${context.currentLanguage.nativeName}',
                      () => showLanguageSelector(context)),
                  _divider(),
                  _settingRow(Icons.notifications_none_rounded, context.tr('notifications'), () => context.push('/notifications')),
                  _divider(),
                  _settingRow(Icons.logout_rounded, context.tr('logout'), () async {
                    AuthGuard.onLogout();
                    await AuthService.logout();
                    if (context.mounted) context.go('/onboarding');
                  }, fg: AppColors.emergency, iconColor: AppColors.emergency),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderLight);

  Widget _infoRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: iconColor ?? AppColors.inkMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData? icon, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: type,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, size: 16, color: AppColors.inkFaint) : null,
              filled: true,
              fillColor: AppColors.groundAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md), borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String title, VoidCallback onTap, {Color? fg, Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? AppColors.ink),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: fg ?? AppColors.ink))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
