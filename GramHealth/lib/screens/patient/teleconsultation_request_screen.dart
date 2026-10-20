import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../services/api_client.dart';
import '../../services/consultation_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/care_icon_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/offline_voice_recorder.dart';
import '../../services/connectivity_service.dart';

class TeleconsultationRequestScreen extends StatefulWidget {
  const TeleconsultationRequestScreen({super.key});

  @override
  State<TeleconsultationRequestScreen> createState() => _TeleconsultationRequestScreenState();
}

class _TeleconsultationRequestScreenState extends State<TeleconsultationRequestScreen> {
  final List<String> _reasons = const ['General Fever', 'Cough & Cold', 'Skin Issue', 'Stomach Pain', 'Other'];
  final List<String> _timeSlots = const ['Morning (9 AM - 12 PM)', 'Afternoon (1 PM - 4 PM)', 'Evening (5 PM - 8 PM)'];

  String _selectedReason = 'General Fever';
  final _symptomsCtrl = TextEditingController();
  String _selectedTime = 'Morning (9 AM - 12 PM)';
  String _selectedType = 'VIDEO';
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  String? _voiceNoteBase64;

  NetworkStatus _networkStatus = NetworkStatus.online;
  StreamSubscription? _netSub;

  String? _doctorId;
  String _doctorName = '';
  String? _doctorPhone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _doctorId = extra['doctorId'] as String?;
      _doctorName = extra['doctorName'] as String? ?? '';
      _doctorPhone = extra['doctorPhone'] as String?;
    }
  }

  @override
  void initState() {
    super.initState();
    _networkStatus = ConnectivityService.instance.currentStatus;
    _netSub = ConnectivityService.instance.statusStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _networkStatus = s;
        if (s == NetworkStatus.weak && _selectedType == 'VIDEO') _selectedType = 'AUDIO';
      });
    });
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _netSub?.cancel();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedReason.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await ConsultationService.createConsultation(
        reason: _selectedReason,
        symptoms: _symptomsCtrl.text.trim().isEmpty ? null : _symptomsCtrl.text.trim(),
        scheduledTime: _selectedTime,
        doctorId: _doctorId,
        type: _networkStatus == NetworkStatus.offline ? 'OFFLINE' : _selectedType,
        voiceNoteUrl: _voiceNoteBase64,
      );
      if (!mounted) return;
      setState(() => _isSubmitted = true);
      Future.delayed(const Duration(milliseconds: 1800), () { if (mounted) context.pop(); });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.emergency, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error. Please try again.'), backgroundColor: AppColors.emergency, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: AppColors.teal,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.xl)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 64, height: 64, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 32, color: AppColors.surface)),
                  const SizedBox(height: 16),
                  Text(context.tr('request_done'), style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Text(context.tr('urgent_success_msg'), textAlign: TextAlign.center, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.5)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: CareIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
            tooltip: 'Back',
            iconSize: 18,
            size: 44,
          ),
        ),
        leadingWidth: 56,
        title: Text('Request consultation', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor header — single CareCard
            CareCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.tealPale)),
                    child: const Icon(Icons.person_rounded, size: 22, color: AppColors.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_doctorName.isNotEmpty ? 'Dr. $_doctorName' : 'Any available doctor', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2)),
                        const SizedBox(height: 2),
                        Text(_doctorId != null ? 'Assigned on request' : 'We will match you to the next available doctor', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _sectionLabel(context.tr('reason_for_consultation')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _reasons.map((r) {
                final sel = _selectedReason == r;
                return CareChip(label: r, selected: sel, onTap: () => setState(() => _selectedReason = r));
              }).toList(),
            ),
            const SizedBox(height: 18),
            _sectionLabel(_networkStatus == NetworkStatus.offline ? 'Offline — voice note required' : 'Consultation type'),
            const SizedBox(height: 10),
            if (_networkStatus == NetworkStatus.offline)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.amberWash, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: AppColors.amberPale)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.mic_rounded, size: 14, color: AppColors.surface)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('You are offline. Record a voice note below — we will send it automatically when you are back online.', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amberDeep, height: 1.5))),
                  ],
                ),
              )
            else
              Row(
                children: [
                  if (_networkStatus != NetworkStatus.weak)
                    Expanded(child: _typeCard(title: 'Video', subtitle: 'High network', icon: Icons.videocam_rounded, selected: _selectedType == 'VIDEO', onTap: () => setState(() => _selectedType = 'VIDEO'))),
                  if (_networkStatus != NetworkStatus.weak) const SizedBox(width: 10),
                  Expanded(child: _typeCard(title: 'Audio', subtitle: 'Low bandwidth', icon: Icons.call_rounded, selected: _selectedType == 'AUDIO', onTap: () => setState(() => _selectedType = 'AUDIO'))),
                ],
              ),
            const SizedBox(height: 18),
            _sectionLabel(context.tr('describe_symptoms')),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: AppColors.borderLight)),
              child: TextField(
                controller: _symptomsCtrl,
                maxLines: 4, minLines: 3,
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: context.tr('other_symptoms'),
                  hintStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkFaint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OfflineVoiceRecorder(doctorPhone: _doctorPhone, doctorName: _doctorName, onRecordingComplete: (b64) => setState(() => _voiceNoteBase64 = b64.isEmpty ? null : b64)),
            const SizedBox(height: 18),
            _sectionLabel(context.tr('preferred_time')),
            const SizedBox(height: 10),
            ..._timeSlots.map((slot) {
              final sel = _selectedTime == slot;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTime = slot),
                  child: AnimatedContainer(
                    duration: AppMotion.state,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.mint : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: sel ? AppColors.tealPale : AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? AppColors.teal : AppColors.surface, border: Border.all(color: sel ? AppColors.teal : AppColors.border)),
                          child: sel ? const Icon(Icons.check_rounded, size: 12, color: AppColors.surface) : null,
                        ),
                        const SizedBox(width: 10),
                        Text(slot, style: GoogleFonts.manrope(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.tealDeep : AppColors.ink)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
            if (_isSubmitting)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.teal)))
            else
              PrimaryButton(title: context.tr('send_request'), onPress: _handleSubmit, width: double.infinity),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.inkFaint),
                const SizedBox(width: 6),
                Expanded(child: Text('Your request is private and shared only with the assigned clinician.', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkFaint, height: 1.4))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.1));

  Widget _typeCard({required String title, required String subtitle, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.state,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: selected ? AppColors.ink : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: selected ? AppColors.surface.withValues(alpha: 0.14) : AppColors.mint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: selected ? AppColors.surface : AppColors.teal)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppColors.surface : AppColors.ink)),
                Text(subtitle, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? AppColors.surface.withValues(alpha: 0.7) : AppColors.inkMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
