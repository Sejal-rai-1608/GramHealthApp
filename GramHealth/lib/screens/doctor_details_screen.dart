import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/doctors_data.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorId;
  const DoctorDetailsScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  bool _showSuccess = false;

  @override
  Widget build(BuildContext context) {
    final doctor = kDoctors.firstWhere(
      (d) => d.id == widget.doctorId,
      orElse: () => kDoctors.first,
    );
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 180),
            child: Column(
              children: [
                // Hero image header
                SizedBox(
                  height: 350,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: doctor.image,
                          width: double.infinity, height: 350, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: AppColors.secondaryBg),
                        ),
                      ),
                      Positioned(
                        top: 50, left: 20,
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            child: const Icon(Icons.arrow_back, color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctor.name,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text('${doctor.spec} • ${doctor.exp} exp.',
                                    style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showSuccess = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4D),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x4DFF4D4D), blurRadius: 8, offset: Offset(0, 4))
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.bolt, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(context.tr('urgent'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFFFB000)),
                          const SizedBox(width: 6),
                          Text('${doctor.rating} (${doctor.reviews} reviews)',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats
                      Row(
                        children: [
                          Expanded(child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Text(context.tr('fee'), style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.5))),
                              Text(doctor.fee, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryAccent)),
                            ]),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Text(context.tr('patients'), style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.5))),
                              Text(doctor.patients, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryAccent)),
                            ]),
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // About
                      Text(context.tr('about_doctor'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Text(doctor.about,
                          style: TextStyle(fontSize: 14, color: AppColors.textDark.withValues(alpha: 0.8), height: 1.5)),
                      const SizedBox(height: 24),

                      // Availability
                      Text(context.tr('availability'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                            return Container(
                              width: w * 0.45,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x0D000000)),
                                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(days[i][0],
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryAccent)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(days[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                                      Row(children: const [
                                        Icon(Icons.access_time, size: 10, color: AppColors.primaryAccent),
                                        SizedBox(width: 4),
                                        Text('09:00 - 05:00 PM', style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
                                      ]),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Booking footer
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/video-call/${doctor.id}'),
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.videocam_outlined, color: AppColors.textDark, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      title: context.tr('book_appointment'),
                      onPress: () => context.push('/teleconsultation-request'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Urgent success modal
          if (_showSuccess)
            _buildSuccessModal(),
        ],
      ),
    );
  }

  Widget _buildSuccessModal() {
    return GestureDetector(
      onTap: () => setState(() => _showSuccess = false),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(context.tr('request_done'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 12),
                Text(
                  context.tr('urgent_success_msg'),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(title: context.tr('awesome'), onPress: () => setState(() => _showSuccess = false), width: double.infinity),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
