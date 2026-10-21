import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/language_selector_modal.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../services/consultation_service.dart';
import '../../services/call_service.dart';
import '../../widgets/connectivity_badge.dart';
import '../../widgets/voice_note_dialog.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_ai_service.dart';
import '../../widgets/offline_setup_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSpecialistKey = 'spec_all';
  String _userName = '';
  List<DoctorModel> _doctors = [];
  bool _doctorsLoading = true;
  List<ConsultationModel> _activeConsultations = [];
  bool _loadingConsultations = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDoctors();
    _loadConsultations();
    unawaited(OfflineAiService.instance.initialise().then((_) {
      return OfflineAiService.instance.checkModelOnStartup();
    }).catchError((_) {}));
  }

  Future<void> _loadConsultations() async {
    setState(() => _loadingConsultations = true);
    try {
      final activeList = await ConsultationService.listConsultations(status: 'ACTIVE');
      if (mounted) setState(() { _activeConsultations = activeList; _loadingConsultations = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingConsultations = false);
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      final raw = (user['name'] as String? ?? '').trim();
      setState(() => _userName = raw);
    }
  }

  Future<void> _loadDoctors() async {
    setState(() => _doctorsLoading = true);
    try {
      final result = await DoctorService.getDoctors();
      if (mounted) setState(() { _doctors = result; _doctorsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _doctorsLoading = false);
    }
  }

  List<DoctorModel> get _filteredDoctors {
    if (_selectedSpecialistKey == 'spec_all') return _doctors;
    const keyToSpec = {
      'spec_gp': 'general',
      'spec_cardio': 'cardio',
      'spec_neuro': 'neuro',
      'spec_pedia': 'pedia',
    };
    final keyword = (keyToSpec[_selectedSpecialistKey] ?? '').toLowerCase();
    return _doctors.where((d) => d.specialization.toLowerCase().contains(keyword)).toList();
  }

  final _specialistKeys = const ['spec_all', 'spec_gp', 'spec_cardio', 'spec_neuro', 'spec_pedia'];

  // Service definitions — icon + tinted wash + destination
  final _services = const [
    _ServiceMeta(id: '1', titleKey: 'service_consult', icon: Icons.medical_services_outlined, tint: AppColors.tealWash, iconColor: AppColors.teal),
    _ServiceMeta(id: '2', titleKey: 'service_symptoms', icon: Icons.biotech_outlined, tint: AppColors.mintLight, iconColor: AppColors.teal),
    _ServiceMeta(id: '3', titleKey: 'service_medicine', icon: Icons.local_pharmacy_outlined, tint: AppColors.amberWash, iconColor: AppColors.amberDeep),
    _ServiceMeta(id: '4', titleKey: 'service_records', icon: Icons.folder_outlined, tint: AppColors.surfaceDim, iconColor: AppColors.inkSoft),
    _ServiceMeta(id: '5', titleKey: 'service_emergency', icon: Icons.emergency_outlined, tint: AppColors.emergencyWash, iconColor: AppColors.emergency),
    _ServiceMeta(id: '6', titleKey: 'Prescriptions', icon: Icons.receipt_long_outlined, tint: AppColors.amberWash, iconColor: AppColors.amberDeep),
  ];

  void _handleCategoryTap(String id) {
    switch (id) {
      case '1': context.go('/main/doctors'); break;
      case '2': context.go('/main/symptoms'); break;
      case '3': context.push('/medicine'); break;
      case '6': context.go('/prescriptions'); break;
      case '4': context.go('/main/records'); break;
      case '5': context.push('/emergency'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.surface,
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ConnectivityBadge(),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('greeting'),
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkMuted, height: 1.2),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _userName.isEmpty ? 'there' : _userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4, height: 1.15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your care, one clear step at a time.',
                                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Language
                          GestureDetector(
                            onTap: () => showLanguageSelector(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.groundAlt,
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language, size: 14, color: AppColors.teal),
                                  const SizedBox(width: 6),
                                  Text(context.currentLanguage.nativeName,
                                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _circleIcon(Icons.notifications_none_rounded, () => context.push('/notifications')),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.go('/main/profile'),
                            child: Semantics(
                              button: true,
                              label: 'Profile',
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.borderLight, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Banner — single primary signal, opaque ──────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: CareCard(
                    color: AppColors.mintLight,
                    borderColor: AppColors.tealPale,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.verified_outlined, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('free_checkup'),
                                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2)),
                              const SizedBox(height: 3),
                              Text(context.tr('checkup_subtitle'),
                                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadii.md)),
                            child: Text(context.tr('learn_more'),
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Offline setup ───────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 0), child: OfflineSetupCard()),
              ),

              // ── Active consultations ────────────────────────────────
              if (!_loadingConsultations && _activeConsultations.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text('Active consultations',
                            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.2)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(AppRadii.pill)),
                          child: Text('${_activeConsultations.length}',
                              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: _activeConsultations.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, i == _activeConsultations.length - 1 ? 0 : 10),
                    child: _ActiveConsultationCard(
                      consultation: _activeConsultations[i],
                      onRemove: () => setState(() => _activeConsultations.removeAt(i)),
                    ),
                  ),
                ),
              ],

              // ── Services — vertical scannable list, one dominant action ─
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How can we help today?',
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text('Choose a task — everything else stays one tap away.',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkMuted, height: 1.4)),
                      const SizedBox(height: 14),
                      // Featured primary — Consult Doctor
                      _FeaturedServiceTile(
                        service: _services[0],
                        onTap: () => _handleCategoryTap('1'),
                      ),
                      const SizedBox(height: 10),
                      // Remaining as compact rows
                      ..._services.sublist(1).map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ServiceRow(service: s, onTap: () => _handleCategoryTap(s.id)),
                          )),
                    ],
                  ),
                ),
              ),

              // ── Specialists ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Text('Specialists',
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/main/doctors'),
                        child: Text(context.tr('explore_all'),
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.teal),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    itemCount: _specialistKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final key = _specialistKeys[i];
                      final active = _selectedSpecialistKey == key;
                      return CareChip(
                        label: context.tr(key),
                        selected: active,
                        onTap: () => setState(() => _selectedSpecialistKey = key),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 188,
                  child: _doctorsLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                      : _filteredDoctors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 28, color: AppColors.inkFaint),
                                  const SizedBox(height: 8),
                                  Text('No doctors for this filter',
                                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _selectedSpecialistKey = 'spec_all'),
                                    child: Text('Show all', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                              itemCount: _filteredDoctors.length,
                              itemBuilder: (_, i) => _DoctorCard(doc: _filteredDoctors[i]),
                            ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // ── FAB — single, teal, raised ──────────────────────────────
          Positioned(
            right: 16,
            bottom: 20,
            child: GestureDetector(
              onTap: () => context.push('/chatbot'),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  boxShadow: const [AppColors.shadowRaised],
                ),
                child: const Icon(Icons.chat_bubble_rounded, size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight)),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _ServiceMeta {
  final String id;
  final String titleKey;
  final IconData icon;
  final Color tint;
  final Color iconColor;
  const _ServiceMeta({required this.id, required this.titleKey, required this.icon, required this.tint, required this.iconColor});
}

class _FeaturedServiceTile extends StatelessWidget {
  final _ServiceMeta service;
  final VoidCallback onTap;
  const _FeaturedServiceTile({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(14)),
            child: Icon(service.icon, size: 26, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.amberWash, borderRadius: BorderRadius.circular(6)),
                  child: Text('RECOMMENDED',
                      style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.amberDeep, letterSpacing: 0.6)),
                ),
                const SizedBox(height: 6),
                Text(context.tr(service.titleKey),
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2)),
                const SizedBox(height: 2),
                Text('Talk to a verified doctor now',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final _ServiceMeta service;
  final VoidCallback onTap;
  const _ServiceRow({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEmergency = service.id == '5';
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: isEmergency ? AppColors.emergencyPale : AppColors.borderLight,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: service.tint, borderRadius: BorderRadius.circular(11)),
            child: Icon(service.icon, size: 20, color: service.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(context.tr(service.titleKey),
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 18, color: isEmergency ? AppColors.emergency : AppColors.inkFaint),
        ],
      ),
    );
  }
}

class _ActiveConsultationCard extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback onRemove;
  const _ActiveConsultationCard({required this.consultation, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isAudio = consultation.type.toUpperCase() == 'AUDIO';
    final isOffline = ConnectivityService.instance.currentStatus == NetworkStatus.offline;
    return CareCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: isAudio ? AppColors.amberWash : AppColors.mint, borderRadius: BorderRadius.circular(10)),
                child: Icon(isAudio ? Icons.call_rounded : Icons.videocam_rounded, size: 18, color: isAudio ? AppColors.amberDeep : AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(consultation.reason.isNotEmpty ? consultation.reason : 'Consultation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(isOffline ? 'Saved offline — will sync when online' : 'Ready to join',
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                  ],
                ),
              ),
              if (!isOffline)
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () async {
                      await CallService.startCall(
                        context: context,
                        consultationId: consultation.id,
                        audioOnly: isAudio,
                        doctorId: consultation.doctorId,
                        doctorName: consultation.doctorName,
                        doctorPhone: consultation.doctorPhone,
                      );
                      onRemove();
                      try { await ConsultationService.updateStatus(consultation.id, 'COMPLETED'); } catch (_) {}
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isAudio ? AppColors.amberDeep : AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(isAudio ? 'Audio' : 'Join', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          if (isOffline) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => VoiceNoteDialog(consultationId: consultation.id)),
                      icon: const Icon(Icons.mic_rounded, size: 16),
                      label: Text('Record note', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: FilledButton.icon(
                      onPressed: () => CallService.startCall(
                        context: context,
                        consultationId: consultation.id,
                        audioOnly: isAudio,
                        doctorId: consultation.doctorId,
                        doctorName: consultation.doctorName,
                        doctorPhone: consultation.doctorPhone,
                      ),
                      icon: const Icon(Icons.call_rounded, size: 16),
                      label: Text('Call', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doc;
  const _DoctorCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/doctor-details/${doc.id}'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        child: CareCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: doc.image,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppColors.mint,
                        alignment: Alignment.center,
                        child: Text(doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. ${doc.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2)),
                        const SizedBox(height: 2),
                        Text(doc.specialization,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                        if (doc.hospital != null && doc.hospital!.isNotEmpty)
                          Text(doc.hospital!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.inkFaint)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton(
                  onPressed: () => context.push('/teleconsultation-request', extra: {'doctorId': doc.id, 'doctorName': doc.name}),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(context.tr('book_now'), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
