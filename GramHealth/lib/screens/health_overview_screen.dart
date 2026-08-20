import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';

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

class _HealthOverviewScreenState extends State<HealthOverviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
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
      backgroundColor: const Color(0xFFF7F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left, size: 24, color: AppColors.textDark),
                    ),
                  ),
                  Text(
                    context.tr('overview'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.tune, size: 20, color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            // Visualizer & Stats Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    // Anatomy area
                    SizedBox(
                      height: 520,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 360 Rotation Ring
                          Positioned(
                            top: 180,
                            child: Container(
                              width: w * 0.8,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: AppColors.indigo.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 220,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.indigo,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '360°',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),

                          // Human body illustration
                          Center(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1530497610245-94d3c16cda28?w=400',
                              width: w * 0.5,
                              height: 380,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.accessibility_new,
                                size: 260,
                                color: AppColors.indigo.withValues(alpha: 0.3),
                              ),
                            ),
                          ),

                          // Pulsing Hotspots
                          _buildHotspot(w * 0.48, 140), // Chest
                          _buildHotspot(w * 0.48, 80),  // Head
                          _buildHotspot(w * 0.44, 230), // Stomach
                          _buildHotspot(w * 0.36, 180), // Arm L
                          _buildHotspot(w * 0.60, 180), // Arm R

                          // Left Metrics
                          Positioned(
                            top: 80,
                            left: 16,
                            child: _buildMetricCard(context.tr('oxygen_level'), '${kPatientData.oxygen}%', Icons.air),
                          ),
                          Positioned(
                            top: 260,
                            left: 16,
                            child: _buildMetricCard(context.tr('kidney'), '${kPatientData.kidney} mL/m', Icons.medical_services_outlined),
                          ),

                          // Right Metrics
                          Positioned(
                            top: 60,
                            right: 16,
                            child: _buildMetricCard(context.tr('heart_rate'), '${kPatientData.heartRate} bpm', Icons.favorite_outline),
                          ),
                          Positioned(
                            top: 240,
                            right: 16,
                            child: _buildMetricCard(context.tr('blood_pressure'), kPatientData.bp, Icons.timeline),
                          ),
                          Positioned(
                            top: 380,
                            right: 16,
                            child: _buildMetricCard(context.tr('cholesterol_level'), '${kPatientData.cholesterol} mg/dL', Icons.opacity),
                          ),
                        ],
                      ),
                    ),

                    // Stats Card Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${kPatientData.height} cm',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(context.tr('height'), style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFF7F8FF), width: 3),
                                    image: DecorationImage(
                                      image: NetworkImage(kPatientData.avatar),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  kPatientData.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${kPatientData.weight} kg',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(context.tr('weight'), style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHotspot(double x, double y) {
    return Positioned(
      left: x,
      top: y,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = 1.0 + (_pulseCtrl.value * 0.5);
          final opacity = (1.0 - _pulseCtrl.value * 0.6).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.indigo.withValues(alpha: opacity * 0.4),
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.indigo, width: 2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.indigo),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Color(0xFF999999), fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
