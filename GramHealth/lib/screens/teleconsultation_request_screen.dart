import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../services/api_client.dart';
import '../services/consultation_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/offline_voice_recorder.dart';
import '../services/connectivity_service.dart';

class TeleconsultationRequestScreen extends StatefulWidget {
  const TeleconsultationRequestScreen({super.key});

  @override
  State<TeleconsultationRequestScreen> createState() => _TeleconsultationRequestScreenState();
}

class _TeleconsultationRequestScreenState extends State<TeleconsultationRequestScreen> {
  final List<String> _reasons = ['General Fever', 'Cough & Cold', 'Skin Issue', 'Stomach Pain', 'Other'];
  final List<String> _timeSlots = [
    'Morning (9 AM - 12 PM)',
    'Afternoon (1 PM - 4 PM)',
    'Evening (5 PM - 8 PM)',
  ];

  String _selectedReason = 'General Fever';
  final TextEditingController _symptomsCtrl = TextEditingController();
  String _selectedTime = 'Morning (9 AM - 12 PM)';
  String _selectedType = 'VIDEO'; // VIDEO or AUDIO
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  String? _voiceNoteBase64;

  NetworkStatus _networkStatus = NetworkStatus.online;
  StreamSubscription? _netSub;

  // Doctor info passed via GoRouter extras
  String? _doctorId;
  String _doctorName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) {
      _doctorId   = extra['doctorId']   as String?;
      _doctorName = extra['doctorName'] as String? ?? '';
    }
  }

  @override
  void initState() {
    super.initState();
    _networkStatus = ConnectivityService.instance.currentStatus;
    _netSub = ConnectivityService.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _networkStatus = status;
          if (status == NetworkStatus.weak && _selectedType == 'VIDEO') {
             _selectedType = 'AUDIO';
          }
        });
      }
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
        symptoms: _symptomsCtrl.text.trim().isEmpty
            ? null
            : _symptomsCtrl.text.trim(),
        scheduledTime: _selectedTime,
        doctorId: _doctorId,
        type: _networkStatus == NetworkStatus.offline ? 'OFFLINE' : _selectedType,
        voiceNoteUrl: _voiceNoteBase64,
      );
      if (!mounted) return;
      setState(() => _isSubmitted = true);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) context.pop();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return Scaffold(
        backgroundColor: AppColors.primaryAccent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('request_done'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('urgent_success_msg'),
                    style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.7), height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left, size: 24, color: AppColors.textDark),
                    ),
                  ),
                  Text(
                    context.tr('send_request'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Summary
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 24, color: AppColors.primaryAccent),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _doctorName.isNotEmpty ? 'Dr. $_doctorName' : context.tr('spec_gp'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              ),
                              Text(
                                _doctorId != null ? context.tr('spec_gp') : context.tr('send_request'),
                                style: TextStyle(fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reasons
                    Text(
                      context.tr('reason_for_consultation'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reasons.map((r) {
                        final isSel = _selectedReason == r;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedReason = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primaryAccent : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel ? AppColors.primaryAccent : const Color(0xFFEEEEEE),
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              r,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSel ? AppColors.textDark : const Color(0xFF666666),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Consultation Type (Adaptive Bandwidth)
                    Text(
                      _networkStatus == NetworkStatus.offline 
                          ? 'Offline Mode Active' 
                          : context.tr('consultation_type'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
                    ),
                    const SizedBox(height: 12),
                    if (_networkStatus == NetworkStatus.offline)
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                         child: Text("You are completely offline. You must record a voice note below instead of requesting a live call. We will automatically send it to the doctor when your internet returns.", style: TextStyle(color: Colors.orange.shade800)),
                       )
                    else 
                    Row(
                      children: [
                        if (_networkStatus != NetworkStatus.weak)
                           Expanded(
                             child: GestureDetector(
                               onTap: () => setState(() => _selectedType = 'VIDEO'),
                               child: _buildTypeCard(
                                 title: 'Video Call',
                                 subtitle: 'High Network Required',
                                 icon: Icons.videocam,
                                 isSelected: _selectedType == 'VIDEO',
                               ),
                             ),
                           ),
                        if (_networkStatus != NetworkStatus.weak) const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = 'AUDIO'),
                            child: _buildTypeCard(
                              title: 'Audio Call',
                              subtitle: 'Low Bandwidth (Rural App)',
                              icon: Icons.call,
                              isSelected: _selectedType == 'AUDIO',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Symptoms

                    Text(
                      context.tr('describe_symptoms'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _symptomsCtrl,
                              maxLines: 4,
                              minLines: 3,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                              decoration: InputDecoration(
                                hintText: context.tr('other_symptoms'),
                                hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OfflineVoiceRecorder(
                      onRecordingComplete: (base64) {
                        setState(() {
                          _voiceNoteBase64 = base64.isEmpty ? null : base64;
                        });
                      }
                    ),
                    const SizedBox(height: 24),

                    // Time slots
                    Text(
                      context.tr('preferred_time'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_timeSlots.length, (i) {
                      final slot = _timeSlots[i];
                      final isSel = _selectedTime == slot;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = slot),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primaryAccent.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel ? AppColors.primaryAccent : const Color(0xFFEEEEEE),
                            ),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSel ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 20,
                                color: isSel ? AppColors.primaryAccent : const Color(0xFFCCCCCC),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? AppColors.textDark : const Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    _isSubmitting
                        ? const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          ))
                        : PrimaryButton(
                            title: context.tr('send_request'),
                            onPress: _handleSubmit,
                            width: double.infinity,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({required String title, required String subtitle, required IconData icon, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryAccent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primaryAccent : const Color(0xFFEEEEEE)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: isSelected ? Colors.white : AppColors.primaryAccent),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey[500])),
        ],
      ),
    );
  }
}
