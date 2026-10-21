import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../services/doctor_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/primary_button.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final String doctorId;
  const DoctorDetailsScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  bool _showSuccess = false;
  DoctorModel? _doctor;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final doc = await DoctorService.getDoctorById(widget.doctorId);
      if (mounted) setState(() { _doctor = doc; _isLoading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load doctor.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.ground,
        body: const Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }
    if (_error != null || _doctor == null) {
      return Scaffold(
        backgroundColor: AppColors.ground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink), onPressed: () => context.pop()),
          title: Text('Doctor', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined, size: 40, color: AppColors.inkFaint),
                const SizedBox(height: 12),
                Text(_error ?? 'Doctor not found.', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadDoctor, style: FilledButton.styleFrom(backgroundColor: AppColors.teal), child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    final doctor = _doctor!;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.surface,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.borderLight)),
                      child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: doctor.image,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.mint, child: const Icon(Icons.person_rounded, size: 64, color: AppColors.teal)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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
                                Text('Dr. ${doctor.name}',
                                    style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.2)),
                                const SizedBox(height: 4),
                                Text('${doctor.specialization}  •  ${doctor.exp}',
                                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (doctor.rating != null) ...[
                                      const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                      const SizedBox(width: 4),
                                      Text('${doctor.rating}  •  ${doctor.reviews} reviews',
                                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                      const SizedBox(width: 10),
                                    ],
                                    if (doctor.isAvailable == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.onlineWash, borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.onlineGreen, shape: BoxShape.circle)),
                                            const SizedBox(width: 5),
                                            Text('Available now', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.onlineGreen)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(() => _showSuccess = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(context.tr('urgent'), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CareCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              child: Column(
                                children: [
                                  Text(context.tr('fee'), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkFaint)),
                                  const SizedBox(height: 4),
                                  Text(doctor.fee, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.teal)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CareCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              child: Column(
                                children: [
                                  Text(context.tr('patients'), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkFaint)),
                                  const SizedBox(height: 4),
                                  Text(doctor.patients, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(context.tr('about_doctor'), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 8),
                      Text(doctor.about, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.6)),
                      const SizedBox(height: 18),
                      Text(context.tr('availability'), style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                            return Container(
                              width: 150,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                                    alignment: Alignment.center,
                                    child: Text(days[i][0], style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(days[i], style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 10, color: AppColors.teal),
                                          const SizedBox(width: 3),
                                          Text('09:00 – 05:00', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Booking footer — opaque, raised
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [AppColors.shadowRaised],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/video-call/${doctor.id}'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.groundAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                      child: const Icon(Icons.videocam_outlined, color: AppColors.ink, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      title: context.tr('book_appointment'),
                      onPress: () => context.push(
                        '/teleconsultation-request',
                        extra: {'doctorId': doctor.id, 'doctorName': doctor.name, 'doctorPhone': doctor.phone},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccess) _SuccessModal(onClose: () => setState(() => _showSuccess = false)),
        ],
      ),
    );
  }
}

class _SuccessModal extends StatelessWidget {
  final VoidCallback onClose;
  const _SuccessModal({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.xl)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(context.tr('request_done'), style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 8),
                Text(context.tr('urgent_success_msg'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.inkSoft, height: 1.5)),
                const SizedBox(height: 18),
                PrimaryButton(title: context.tr('awesome'), onPress: onClose, width: double.infinity),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
