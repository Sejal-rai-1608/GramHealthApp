import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/doctors_data.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/language_selector_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSpecialistKey = 'spec_all';
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
        context.push('/medicine');
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                          const Text(
                            'SEJAL 👋',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=100',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                    color: AppColors.primaryAccent,
                                    child: const Icon(Icons.person,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

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
                            Container(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

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
                      Text(
                        context.tr('explore_all'),
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600),
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
                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: kDoctors.length,
                    itemBuilder: (_, i) => _buildDoctorCard(kDoctors[i], w),
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

  Widget _buildDoctorCard(Doctor doc, double screenW) {
    return Container(
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
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.secondaryBg),
                  ),
                ),
                Positioned(
                  bottom: -5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              size: 10, color: Color(0xFFFFB000)),
                          const SizedBox(width: 2),
                          Text('${doc.rating}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF333333))),
                        ],
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
                  Text(doc.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark),
                      maxLines: 1),
                  Text(doc.spec,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.primaryAccent),
                      const SizedBox(width: 4),
                      const Text('8:00 am - 5:00 pm',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444444))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.push('/teleconsultation-request'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        context.tr('book_now'),
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
    );
  }
}
