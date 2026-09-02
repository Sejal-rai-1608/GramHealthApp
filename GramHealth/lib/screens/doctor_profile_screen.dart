import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../widgets/dashboard_layout.dart';
import '../widgets/glass_card.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isLoading = true;
  String? _error;

  // User fields
  String _name           = '';
  String _email          = '';
  String _phone          = '';

  // Doctor-specific fields
  String _specialization = '';
  String _registrationNo = '';
  String _hospital       = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // First load basic user info from secure storage (instant)
      final user = await AuthService.getUser();
      if (user != null) {
        _name  = user['name']  as String? ?? '';
        _email = user['email'] as String? ?? '';
        _phone = user['phone'] as String? ?? '';
      }

      // Then fetch full doctor profile from API (includes specialization etc.)
      final response = await ApiClient.get('${AppConfig.apiDoctors}/me');
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          _specialization = data['specialization'] as String? ?? '';
          _registrationNo = data['registrationNumber'] as String? ?? '';
          _hospital       = data['hospitalName'] as String? ?? '';
          // user info may also be nested
          final userObj = data['user'] as Map<String, dynamic>?;
          if (userObj != null) {
            _name  = userObj['name']  as String? ?? _name;
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
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _loadProfile,
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    children: [
                      // ── Avatar & Name ──────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.leafGreenPrimary, AppColors.leafGreenMedium],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [BoxShadow(color: AppColors.leafGreenPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _name.isNotEmpty ? 'Dr. $_name' : context.tr('profile'),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            if (_specialization.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.leafGreenPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _specialization,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.leafGreenPrimary),
                                ),
                              )
                            else
                              Text('Doctor', style: TextStyle(fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Professional Details ───────────────────────────────
                      _buildSectionTitle('Professional Details'),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.local_hospital_outlined,
                              'Specialization',
                              _specialization.isNotEmpty ? _specialization : '—',
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.badge_outlined,
                              'Registration No.',
                              _registrationNo.isNotEmpty ? _registrationNo : '—',
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.apartment_outlined,
                              'Hospital / PHC',
                              _hospital.isNotEmpty ? _hospital : '—',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Contact Details ────────────────────────────────────
                      _buildSectionTitle('Contact Information'),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(Icons.email_outlined, 'Email', _email.isNotEmpty ? _email : '—'),
                            const Divider(height: 24),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.leafGreenPrimary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }
}
