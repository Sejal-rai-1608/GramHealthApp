import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import '../../widgets/care_card.dart';
import '../../widgets/care_icon_button.dart';

class PatientData {
  final String name;
  final String height;
  final String weight;
  final String oxygen;
  final String heartRate;
  final String kidney;
  final String bp;
  final String cholesterol;
  final String avatar;

  const PatientData({
    required this.name,
    required this.height,
    required this.weight,
    required this.oxygen,
    required this.heartRate,
    required this.kidney,
    required this.bp,
    required this.cholesterol,
    required this.avatar,
  });
}

const kPatientData = PatientData(
  name: 'Muminul Hoque',
  height: '162',
  weight: '64',
  oxygen: '96',
  heartRate: '76',
  kidney: '98',
  bp: '116/74',
  cholesterol: '168',
  avatar: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=200',
);

class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({super.key});

  @override
  State<HealthOverviewScreen> createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
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
        title: Text(context.tr('overview'), style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Synthetic data notice — these are not real readings
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amberWash,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.amberPale),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amberDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sample data for demonstration only — not your medical readings.',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberDeep,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Anatomy area — keep demo visual, now with teal accents
            SizedBox(
              height: 520,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 180,
                    child: Container(
                      width: w * 0.8,
                      height: 60,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.tealPale.withValues(alpha: 0.6), width: 1.2)),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
                      child: Text('360°', style: GoogleFonts.manrope(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Center(
                    child: Image.network('https://images.unsplash.com/photo-1530497610245-94d3c16cda28?w=400', width: w * 0.5, height: 380, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.accessibility_new_rounded, size: 220, color: AppColors.teal.withValues(alpha: 0.18))),
                  ),
                  _hotspot(w * 0.48, 140),
                  _hotspot(w * 0.48, 80),
                  _hotspot(w * 0.44, 230),
                  _hotspot(w * 0.36, 180),
                  _hotspot(w * 0.60, 180),
                  Positioned(top: 80, left: 16, child: _metricCard(context.tr('oxygen_level'), '${kPatientData.oxygen}%', Icons.air_rounded)),
                  Positioned(top: 260, left: 16, child: _metricCard(context.tr('kidney'), '${kPatientData.kidney} mL/m', Icons.medical_services_outlined)),
                  Positioned(top: 60, right: 16, child: _metricCard(context.tr('heart_rate'), '${kPatientData.heartRate} bpm', Icons.favorite_rounded)),
                  Positioned(top: 240, right: 16, child: _metricCard(context.tr('blood_pressure'), kPatientData.bp, Icons.monitor_heart_outlined)),
                  Positioned(top: 380, right: 16, child: _metricCard(context.tr('cholesterol_level'), '${kPatientData.cholesterol} mg/dL', Icons.water_drop_outlined)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CareCard(
                padding: const EdgeInsets.all(18),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(children: [Text('${kPatientData.height} cm', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)), const SizedBox(height: 4), Text(context.tr('height'), style: GoogleFonts.manrope(fontSize: 11, color: AppColors.inkFaint, fontWeight: FontWeight.w600))]),
                  Column(children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight, width: 2), image: DecorationImage(image: NetworkImage(kPatientData.avatar), fit: BoxFit.cover))),
                    const SizedBox(height: 8),
                    Text(kPatientData.name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ]),
                  Column(children: [Text('${kPatientData.weight} kg', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)), const SizedBox(height: 4), Text(context.tr('weight'), style: GoogleFonts.manrope(fontSize: 11, color: AppColors.inkFaint, fontWeight: FontWeight.w600))]),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hotspot(double x, double y) => Positioned(
        left: x,
        top: y,
        child: Semantics(
          label: 'Body health indicator',
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final scale = 1.0 + (_pulseCtrl.value * 0.5);
              final opacity = (1.0 - _pulseCtrl.value * 0.6).clamp(0.0, 1.0);
              return Stack(alignment: Alignment.center, children: [
                Transform.scale(scale: scale, child: Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.teal.withValues(alpha: opacity * 0.28)))),
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppColors.teal, width: 2))),
              ]);
            },
          ),
        ),
      );

  Widget _metricCard(String title, String value, IconData icon) => Semantics(
        label: '$title: $value',
        child: CareCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 15, color: AppColors.teal)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.manrope(fontSize: 10, color: AppColors.inkFaint, fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ]),
          ]),
        ),
      );
}
