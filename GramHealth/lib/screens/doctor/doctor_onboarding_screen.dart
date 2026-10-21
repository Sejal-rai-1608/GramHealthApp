import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/primary_button.dart';
import '../../services/api_client.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

/// Shown immediately after a doctor account is created.
/// Collects specialization, registration number, and hospital name,
/// then saves them to the backend via PATCH /api/doctors/me.
class DoctorOnboardingScreen extends StatefulWidget {
  const DoctorOnboardingScreen({super.key});

  @override
  State<DoctorOnboardingScreen> createState() => _DoctorOnboardingScreenState();
}

class _DoctorOnboardingScreenState extends State<DoctorOnboardingScreen> {
  final _specCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _hospCtrl = TextEditingController();
  bool _isLoading = false;

  final List<String> _specializations = [
    'General Physician',
    'Pediatrician',
    'Gynecologist',
    'Cardiologist',
    'Orthopedic Surgeon',
    'Dermatologist',
    'Neurologist',
    'Ophthalmologist',
    'ENT Specialist',
    'Psychiatrist',
    'Dentist',
    'Other',
  ];

  @override
  void dispose() {
    _specCtrl.dispose();
    _regCtrl.dispose();
    _hospCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.manrope(color: Colors.white)),
      backgroundColor: AppColors.emergency,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
    ));
  }

  Future<void> _handleSubmit() async {
    final spec = _specCtrl.text.trim();
    final reg = _regCtrl.text.trim();
    final hosp = _hospCtrl.text.trim();

    if (spec.isEmpty) {
      _showError('Please select or enter your specialization.');
      return;
    }
    if (reg.isEmpty) {
      _showError('Please enter your medical registration number.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{
        'specialization': spec,
        'registrationNumber': reg,
        if (hosp.isNotEmpty) 'hospitalName': hosp,
      };
      await ApiClient.patch('${AppConfig.apiDoctors}/me', body);
      final user = await AuthService.getUser() ?? {};
      user['specialization'] = spec;
      user['registrationNo'] = reg;
      user['hospital'] = hosp;
      await AuthService.updateUser(user);
      if (mounted) context.go('/doctor/requests');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Network error. Please try again.');
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.tealPale, width: 2),
                    boxShadow: const [AppColors.shadowLow],
                  ),
                  child: const Icon(Icons.local_hospital_outlined, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Complete Your Doctor Profile',
                  style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'This information helps patients find and trust you.',
                  style: GoogleFonts.manrope(fontSize: 14, color: AppColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Text('Specialization *', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              CareCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _specializations.contains(_specCtrl.text) ? _specCtrl.text : null,
                    hint: Text('Select specialization', style: GoogleFonts.manrope(color: AppColors.inkFaint, fontSize: 13)),
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, color: AppColors.teal),
                    items: _specializations
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _specCtrl.text = val == 'Other' ? '' : val);
                    },
                  ),
                ),
              ),
              if (_specCtrl.text.isEmpty || !_specializations.contains(_specCtrl.text)) ...[
                const SizedBox(height: 8),
                _buildField(
                  controller: _specCtrl,
                  label: 'Enter specialization manually',
                  icon: Icons.medical_services_outlined,
                ),
              ],
              const SizedBox(height: 20),
              Text('Medical Registration No. *',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              _buildField(
                controller: _regCtrl,
                label: 'e.g. MCI-123456 or IMC/2019/12345',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 20),
              Text('Hospital / PHC / Clinic', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('(Optional)', style: GoogleFonts.manrope(fontSize: 12, color: AppColors.inkFaint)),
              const SizedBox(height: 8),
              _buildField(
                controller: _hospCtrl,
                label: 'e.g. District Hospital, Pipariya',
                icon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : PrimaryButton(
                      title: 'Save & Enter App',
                      onPress: _handleSubmit,
                      width: double.infinity,
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/doctor/requests'),
                  child: Text('Skip for now', style: GoogleFonts.manrope(color: AppColors.inkFaint, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon}) {
    return CareCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.manrope(fontSize: 14, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: GoogleFonts.manrope(color: AppColors.inkFaint, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
