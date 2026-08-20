import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/doctors_data.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _filterKeys = ['spec_gp', 'spec_pedia', 'spec_cardio', 'spec_derma'];
  String _activeFilterKey = 'spec_gp';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('consult_doctor'),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF666666), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: context.tr('search_doctor'),
                            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filterKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final key = _filterKeys[i];
                final isActive = _activeFilterKey == key;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilterKey = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryAccent : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 4)],
                    ),
                    child: Text(
                      context.tr(key),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.textDark : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: kDoctors.length,
              itemBuilder: (_, i) => _buildDoctorCard(context, kDoctors[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doc) {
    return GestureDetector(
      onTap: () => context.push('/doctor-details/${doc.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: doc.image,
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppColors.secondaryBg, width: 80, height: 80),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                doc.name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/teleconsultation-request'),
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.videocam_outlined, size: 18, color: AppColors.primaryAccent),
                              ),
                            ),
                          ],
                        ),
                        Text(doc.spec,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.work_outline, size: 12, color: Color(0xFF666666)),
                            const SizedBox(width: 4),
                            Text(doc.exp, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, size: 12, color: Color(0xFFFFB000)),
                            const SizedBox(width: 4),
                            Text('${doc.rating}', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/teleconsultation-request'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.tr('book_consultation'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
