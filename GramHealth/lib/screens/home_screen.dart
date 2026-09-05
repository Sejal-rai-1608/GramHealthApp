import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_selector_modal.dart';
import '../services/auth_service.dart';
import '../services/doctor_service.dart';
import '../services/consultation_service.dart';
import '../services/call_service.dart';
import '../widgets/connectivity_badge.dart';
import '../widgets/voice_note_dialog.dart';
import '../services/connectivity_service.dart';

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
  }

  Future<void> _loadConsultations() async {
    setState(() => _loadingConsultations = true);
    try {
      final activeList = await ConsultationService.listConsultations(status: 'ACTIVE');
      if (mounted) {
        setState(() {
          _activeConsultations = activeList;
          _loadingConsultations = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingConsultations = false);
    }
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _userName = (user['name'] as String? ?? '').toUpperCase();
      });
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

  /// Returns doctors filtered by the selected specialization chip.
  List<DoctorModel> get _filteredDoctors {
    if (_selectedSpecialistKey == 'spec_all') return _doctors;
    final Map<String, String> keyToSpec = {
      'spec_gp':    'general',
      'spec_cardio':'cardio',
      'spec_neuro': 'neuro',
      'spec_pedia': 'pedia',
    };
    final keyword = (keyToSpec[_selectedSpecialistKey] ?? '').toLowerCase();
    return _doctors.where((d) => d.specialization.toLowerCase().contains(keyword)).toList();
  }

  final _specialistKeys = [
    'spec_all',
    'spec_gp',
    'spec_cardio',
    'spec_neuro',
    'spec_pedia',
  ];

  final _categories = [
    {
      'id': '1',
      'titleKey': 'service_consult',
      'icon': Icons.monitor_heart_outlined,
      'color': const Color(0xFFE1F5FE)
    },
    {
      'id': '2',
      'titleKey': 'service_symptoms',
      'icon': Icons.search,
      'color': const Color(0xFFF3E5F5)
    },
    {
      'id': '3',
      'titleKey': 'service_medicine',
      'icon': Icons.local_pharmacy_outlined,
      'color': const Color(0xFFE8F5E9)
    },
    {
      'id': '4',
      'titleKey': 'service_records',
      'icon': Icons.description_outlined,
      'color': const Color(0xFFFFF3E0)
    },
    {
      'id': '5',
      'titleKey': 'service_emergency',
      'icon': Icons.emergency_outlined,
      'color': const Color(0xFFFFEBEE)
    },
    {
      'id': '6',
      'titleKey': 'Prescriptions',
      'icon': Icons.article_outlined,
      'color': const Color(0xFFD1C4E9)
    },
  ];

  void _handleCategoryTap(String id) {
    switch (id) {
      case '1':
        context.go('/main/doctors');
        break;
      case '2':
        context.go('/main/symptoms');
        break;
      case '3':
        context.go('/medicine');
        break;
      case '6':
        context.go('/prescriptions');
        break;
      case '4':
        context.go('/main/records');
        break;
      case '5':
        context.push('/emergency');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ConnectivityBadge(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('greeting'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              '${_userName.isEmpty ? context.tr('greeting') : _userName} 👋',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Language Switcher Button
                          GestureDetector(
                            onTap: () => showLanguageSelector(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x14000000), blurRadius: 4)
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.language,
                                      size: 18, color: AppColors.textDark),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.currentLanguage.nativeName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _iconButton(Icons.notifications_none_outlined,
                              () => context.push('/notifications')),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.go('/main/profile'),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primaryAccent,
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0]
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ], // row children close
                  ), // row close
                ], // column children close
              ), // column close
            ), // container close

                // Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryAccent, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(Icons.shield_outlined,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('free_checkup'),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('checkup_subtitle'),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark
                                      .withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => context.push('/notifications'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: AppColors.textDark,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  context.tr('learn_more'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Consultations
                if (!_loadingConsultations && _activeConsultations.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Text(
                      'Your Active Consultations',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                  ..._activeConsultations.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(c.type.toUpperCase() == 'AUDIO' ? Icons.call : Icons.videocam, color: AppColors.primaryAccent),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.reason.isNotEmpty ? c.reason : 'Consultation',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ready to join',
                                  style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (ConnectivityService.instance.currentStatus == NetworkStatus.offline) {
                                showDialog(
                                  context: context,
                                  builder: (context) => VoiceNoteDialog(consultationId: c.id),
                                );
                              } else {
                                CallService.startCall(
                                  consultationId: c.id,
                                  audioOnly: c.type.toUpperCase() == 'AUDIO',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ConnectivityService.instance.currentStatus == NetworkStatus.offline
                                  ? Colors.orangeAccent
                                  : (c.type.toUpperCase() == 'AUDIO' ? Colors.blueAccent : AppColors.primaryAccent),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              ConnectivityService.instance.currentStatus == NetworkStatus.offline
                                  ? 'Record Note'
                                  : (c.type.toUpperCase() == 'AUDIO' ? 'Audio' : 'Join'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                ],

                // Services grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    context.tr('our_services'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories
                        .map((cat) => _buildServiceCard(cat, w))
                        .toList(),
                  ),
                ),

                // Specialists section
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('our_specialists'),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/main/doctors'),
                        child: Text(
                          context.tr('explore_all'),
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _specialistKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final key = _specialistKeys[i];
                      final isActive = _selectedSpecialistKey == key;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedSpecialistKey = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primaryAccent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: isActive
                                    ? AppColors.primaryAccent
                                    : const Color(0xFFEEEEEE)),
                          ),
                          child: Text(
                            context.tr(key),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.textDark
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Doctor carousel
                const SizedBox(height: 12),
                if (_doctorsLoading)
                  const SizedBox(
                    height: 170,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filteredDoctors.isEmpty)
                  SizedBox(
                    height: 170,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined, size: 36, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No doctors found', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (_, i) => _buildDoctorCard(_filteredDoctors[i], w),
                    ),
                  ),
              ],
            ),
          ),

          // Floating chatbot FAB
          Positioned(
            bottom: 90,
            right: 20,
            child: GestureDetector(
              onTap: () => context.push('/chatbot'),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryAccent, Color(0xFFA8E063)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.insights,
                    size: 28, color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 24, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildServiceCard(Map cat, double screenW) {
    return GestureDetector(
      onTap: () => _handleCategoryTap(cat['id'] as String),
      child: SizedBox(
        width: (screenW - 56) / 2,
        height: 150,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat['color'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat['icon'] as IconData,
                    size: 28, color: AppColors.textDark),
              ),
              Text(
                context.tr(cat['titleKey'] as String),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doc, double screenW) {
    return GestureDetector(
      onTap: () => context.push('/doctor-details/${doc.id}'),
      child: Container(
        width: screenW * 0.75,
        margin: const EdgeInsets.only(right: 16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: doc.image,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.leafGreenPale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          doc.name.isNotEmpty ? doc.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.leafGreenPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Dr. ${doc.name}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(doc.specialization,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1),
                    if (doc.hospital != null && doc.hospital!.isNotEmpty) ...[  
                      const SizedBox(height: 2),
                      Text(doc.hospital!,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.push(
                        '/teleconsultation-request',
                        extra: {'doctorId': doc.id, 'doctorName': doc.name},
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.textDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          context.tr('book_now'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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
    );
  }
}
