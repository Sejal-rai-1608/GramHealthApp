import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../widgets/dashboard_layout.dart';
import '../../widgets/care_card.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../config/app_config.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isLoading = true;
  String? _error;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _specialization = '';
  String _registrationNo = '';
  String _hospital = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        _name = user['name'] as String? ?? '';
        _email = user['email'] as String? ?? '';
        _phone = user['phone'] as String? ?? '';
      }
      final response = await ApiClient.get('${AppConfig.apiDoctors}/me');
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          _specialization = data['specialization'] as String? ?? '';
          _registrationNo = data['registrationNumber'] as String? ?? '';
          _hospital = data['hospitalName'] as String? ?? '';
          final userObj = data['user'] as Map<String, dynamic>?;
          if (userObj != null) {
            _name = userObj['name'] as String? ?? _name;
            _email = userObj['email'] as String? ?? _email;
            _phone = userObj['phone'] as String? ?? _phone;
          }
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load profile.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: context.tr('profile'),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: GoogleFonts.manrope(color: AppColors.emergency, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                        ),
                        onPressed: _loadProfile,
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _loadProfile,
                  child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.teal,
                                border: Border.all(color: AppColors.tealPale, width: 3),
                                boxShadow: const [AppColors.shadowLow],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                                style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _name.isNotEmpty ? 'Dr. $_name' : context.tr('profile'),
                              style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                            const SizedBox(height: 6),
                            if (_specialization.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.mint,
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                  border: Border.all(color: AppColors.tealPale),
                                ),
                                child: Text(
                                  _specialization,
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.tealDeep),
                                ),
                              )
                            else
                              Text('Doctor', style: GoogleFonts.manrope(fontSize: 13, color: AppColors.inkFaint)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text('Professional Details',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMuted, letterSpacing: 0.6)),
                      const SizedBox(height: 10),
                      CareCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.local_hospital_outlined, 'Specialization',
                                _specialization.isNotEmpty ? _specialization : '—'),
                            const Divider(height: 24, color: AppColors.borderLight),
                            _buildInfoRow(Icons.badge_outlined, 'Registration No.',
                                _registrationNo.isNotEmpty ? _registrationNo : '—'),
                            const Divider(height: 24, color: AppColors.borderLight),
                            _buildInfoRow(Icons.apartment_outlined, 'Hospital / PHC',
                                _hospital.isNotEmpty ? _hospital : '—'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Contact Information',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkMuted, letterSpacing: 0.6)),
                      const SizedBox(height: 10),
                      CareCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.email_outlined, 'Email', _email.isNotEmpty ? _email : '—'),
                            const Divider(height: 24, color: AppColors.borderLight),
                            _buildInfoRow(Icons.phone_outlined, 'Phone', _phone.isNotEmpty ? _phone : '—'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.mintLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.teal, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkFaint, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ],
          ),
        ),
      ],
    );
  }
}
